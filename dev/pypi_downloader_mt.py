from lxml import html, etree
import requests
import re
import argparse
import os
import datetime
import shutil
import logging
import sys
import concurrent.futures
import itertools
import threading
import functools

class DownloadErrorCounter():
    """ Class for tracking download errors in a thread-safe way """
    def __init__(self):
        self.error_count = 0
        self.lock = threading.Lock()

    def update_counter(self):
        with self.lock:
            self.error_count += 1

    def get_counter(self):
        return self.error_count
    

# This function grabs a list of all the packages at the pypi index site specified by 'baseurl'
def getPackageListFromIndex(baseurl):
    newpkgs = []
    retpkgs = []

    try:
        page = requests.get(baseurl + "/simple/")
        page.raise_for_status()
        tree = html.fromstring(page.content)
        pkgs = tree.xpath("//@href")

        for p in pkgs:
            # Here we look for the simple package name for the package item
            # returned in package list
            pkg_name_match = re.search(r"simple/(.*)/", p, re.IGNORECASE)
            if pkg_name_match:
                tmp = pkg_name_match.group(1)
                newpkgs.append(tmp)
            else:
                newpkgs.append(p)
    except requests.ConnectionError as err:
        logging.warn("Connection error while getting package list: {0}".format(err))
    except requests.HTTPError as err:
        logging.warn("HTTP unsuccessful response while getting package list: {0}".format(err))
    except requests.Timeout as err:
        logging.warn("Timeout error while getting package list: {0}".format(err))
    except requests.TooManyRedirects as err:
        logging.warn("TooManyRedirects error while getting package list: {0}".format(err))
    except Exception as err:
        logging.warn("Unknown Error: {}".format(err))
    else:
        retpkgs = newpkgs

    return retpkgs
        

# This function parses the command line arguments
def parseCommandLine():
    parser = argparse.ArgumentParser(
        description="Script to mirror pypi packages",
        epilog="If neither '-c' nor '-i' are given, packages are read from stdin."
        )
    parser.add_argument('-m', dest='mirror_tld', default='/mirror1/repos', help='Base directory to store repos')
    parser.add_argument('-r', dest='repo_name', help='repo name for storing packages in', required=True)
    parser.add_argument('-u', dest='repo_url', default='https://pypi.org', help='URL of pypi index site')
    parser.add_argument('-t', dest='thread_count', type=int, default=5, help='Number of threads to use for downloading files')
    group = parser.add_mutually_exclusive_group()
    group.add_argument('-c', dest='config_file', type=argparse.FileType('r'), help='file to parse packages name to download')
    group.add_argument('-i', dest='index', action='store_true', help='pypi index site to get packages from')
    group.add_argument('-p', dest='package_name', help='name of package to install')

    args = parser.parse_args()

    return args


# This function downloads an a file given a dictionary of file information from pypi.org
def downloadReleaseFile(file_download_info, base_save_loc, download_error_counter):
    web_loc = base_save_loc
    file = file_download_info

    # Here we parse out some information from the returned json object for later use
    file_name = file['filename']
    file_url = file['url']
    file_url_md5 = file['digests']['md5']
    file_url_size = file['size']  # In bytes
    file_url_time = file['upload_time']  # time format returned: 2019-04-16T20:36:54
    file_url_time_epoch = int(datetime.datetime.strptime(file_url_time, '%Y-%m-%dT%H:%M:%S').timestamp())  # Epoch time version of file_url_time

    # Here we need to parse out the directory structure for locally storing the file
    parsed_dir_match = re.search(r"http[s]{0,1}://[^/]+/(.*)/", file_url, re.IGNORECASE)
    if parsed_dir_match:
        parsed_dir = parsed_dir_match.group(1)
        file_loc = web_loc + "/" + parsed_dir + "/" + file_name
        file_dir = web_loc + "/" + parsed_dir
        # Here we first get the stats of a possible already existing file
        download_file = False
        if os.path.exists(file_loc):
            file_info = os.stat(file_loc)
            file_size = file_info.st_size
            file_mod_time = file_info.st_mtime

            # Here we check if the file should be overwritten
            if file_url_size != file_size or file_url_time_epoch > file_mod_time:
                download_file = True

        else:
            download_file = True

        if download_file:
            # Here we download the file
            #print("[INFO]: Downloading " + file_name + "...")
            try:
                logging.info("Downloading " + file_name + "...")
                os.makedirs(file_dir, exist_ok=True)  # create (if not existing) path to file to be saved
                package_file_req = requests.get(file_url, stream=True)
                package_file_req.raise_for_status()
                with open(file_loc, 'wb') as outfile:
                    shutil.copyfileobj(package_file_req.raw, outfile)
                os.utime(file_loc, (file_url_time_epoch, file_url_time_epoch))
            except requests.ConnectionError as err:
                logging.warn("Connection error while getting package file " + file_name + ": {0}".format(err))
                download_error_counter.update_counter()
            except requests.HTTPError as err:
                logging.warn("HTTP unsuccessful response while getting package file " + file_name + ": {0}".format(err))
                download_error_counter.update_counter()
            except requests.Timeout as err:
                logging.warn("Timeout error while getting package file " + file_name + ": {0}".format(err))
                download_error_counter.update_counter()
            except requests.TooManyRedirects as err:
                logging.warn("TooManyRedirects error while getting package file " + file_name + ": {0}".format(err))
                download_error_counter.update_counter()
            except Exception as err:
                logging.warn("Unknown Error: {}".format(err))
                download_error_counter.update_counter()
        else:
            logging.info(file_name + " exists, skipping...")

    else:
        logging.warn("No package file url matched, skipping...")
        download_error_counter.update_counter()

# This function checks the package serial number and compares it to the local serial number to determine if the package should be downloaded
def shouldDownload(pkg, base_url, base_file_loc):
    simple_loc = base_file_loc + "/" + "web" + "/" + "simple"
    should_download = False
    pkg_index_loc = simple_loc + "/" + pkg + "/index.html"

    try:
        if os.path.exists(pkg_index_loc):
            tree = html.parse(pkg_index_loc)

            # Here parse for the serial number in the comments of the page
            comments = tree.xpath("//comment()")
            for c in comments:
                print(c)
                should_download = True
        else:
            should_download = True
    except requests.ConnectionError as err:
        logging.warn("Connection error while getting index for package " + pkg + ": {0}".format(err))
    except requests.HTTPError as err:
        logging.warn("HTTP unsuccessful response while getting index for package " + pkg + ": {0}".format(err))
    except requests.Timeout as err:
        logging.warn("Timeout error while getting index for package " + pkg + ": {0}".format(err))
    except requests.TooManyRedirects as err:
        logging.warn("TooManyRedirects error while getting index for package " + pkg + ": {0}".format(err))
    except Exception as err:
        logging.warn("Unknown Error: {}".format(err))
    
    return should_download

# This function parses the package index file and writes it with relative path for the package files
def processPackageIndex(pkg, base_url, base_save_loc):
    simple_loc = base_save_loc + "/" + "web" + "/" + "simple"
    error_found = True

    try:
        page = requests.get(base_url + "/simple/" + pkg)
        page.raise_for_status()
        tree = html.fromstring(page.content)

        # Here we get the list of urls to the package file versions to make into a relative
        # path to save as our localized index.html for that package
        a_tags = tree.xpath("//a")
        for a in a_tags:
            orig_url = a.get("href")
            new_url = re.sub(r"http\w*://.*/packages", "../../packages", orig_url, 1, re.IGNORECASE)
            a.set("href", new_url)

        # Here we write out the localized package index.html
        doc = etree.ElementTree(tree)
        save_loc = simple_loc + "/" + pkg
        os.makedirs(save_loc, exist_ok=True)
        doc.write(save_loc + "/" + "index.html")
    except requests.ConnectionError as err:
        logging.warn("Connection error while getting index for package " + pkg + ": {0}".format(err))
    except requests.HTTPError as err:
        logging.warn("HTTP unsuccessful response while getting index for package " + pkg + ": {0}".format(err))
    except requests.Timeout as err:
        logging.warn("Timeout error while getting index for package " + pkg + ": {0}".format(err))
    except requests.TooManyRedirects as err:
        logging.warn("TooManyRedirects error while getting index for package " + pkg + ": {0}".format(err))
    except Exception as err:
        logging.warn("Unknown Error: {}".format(err))
    else:
        error_found = False

    return error_found


# This function downloads package files if they are newer or of a differing size
def processPackageFiles(pkg_name, base_url, base_save_loc, thread_count):
    web_loc = base_save_loc + "/" + "web"
    error_found = False
    error_count = 0
    download_counter = DownloadErrorCounter()
    partialed_download_release_file = functools.partial(downloadReleaseFile, base_save_loc=web_loc, download_error_counter=download_counter)

    # Here we get the json info page for the package
    try:
        page = requests.get(base_url + "/pypi/" + pkg_name + "/json")
        page.raise_for_status()
        if page.status_code == 200:
            json_page = page.json()

            if len(json_page['releases']) > 0:
                for release in json_page['releases']:
                    if len(json_page['releases'][release]) > 0:
                        files = json_page['releases'][release]
                        with concurrent.futures.ThreadPoolExecutor(max_workers=thread_count) as executor:
                            executor.map(partialed_download_release_file, files)
    except requests.ConnectionError as err:
        logging.warn("Connection error while getting json info for package " + pkg_name + ": {0}".format(err))
        error_count += 1
    except requests.HTTPError as err:
        logging.warn("HTTP unsuccessful response while getting json info for package " + pkg_name + ": {0}".format(err))
        error_count += 1
    except requests.Timeout as err:
        logging.warn("Timeout error while getting json info for package " + pkg_name + ": {0}".format(err))
        error_count += 1
    except requests.TooManyRedirects as err:
        logging.warn("TooManyRedirects error while getting json info for package " + pkg_name + ": {0}".format(err))
        error_count += 1
    except Exception as err:
        logging.warn("Unknown Error: {}".format(err))
        error_count += 1

    if error_count > 0 or download_counter.get_counter() > 0:
        error_found = True
    return error_found

######################################### Start of main processing

if __name__ == "__main__":
    
    logging.basicConfig(level=logging.INFO, format='[%(levelname)s]: %(message)s')
    args = parseCommandLine()

    mirror_tld = args.mirror_tld
    repo_name = args.repo_name
    repo_url = args.repo_url
    mirror_repo_loc = mirror_tld + "/" + repo_name
    thread_count = args.thread_count

    if args.config_file:
        logging.info("Grabbing list of packages from file: " + args.config_file.name)
        pkgs = args.config_file.read().split()
    elif args.index:
        logging.info("Grabbing list of packages from pypi index: " + repo_url)
        pkgs = getPackageListFromIndex(repo_url)
    elif args.package_name:
        logging.info("Grabbing package name from command line: " + args.package_name)
        pkgs = []
        pkgs.append(args.package_name)
    else:
        logging.info("Grabbing list of packages from stdin...")
        pkgs = sys.stdin.read().split()

    for p in pkgs:
        logging.info("Processing package " + p + "...")
        if shouldDownload(p, repo_url, mirror_repo_loc):
            err = processPackageIndex(p, repo_url, mirror_repo_loc)
            if err:
                logging.warn("Failed to process package " + p + " due to error while getting package information")
            else:
                err2 = processPackageFiles(p, repo_url, mirror_repo_loc, thread_count)
                if err2:
                    logging.warn("Error while downloading files for package: " + p)
                else:
                    logging.info("Successful processing of package {}".format(p))
