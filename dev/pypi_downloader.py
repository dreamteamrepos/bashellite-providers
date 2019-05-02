from lxml import html, etree
import requests, re, argparse, os, datetime, shutil


# This function grabs a list of all the packages at the pypi index site specified by 'baseurl'
def getPackageList(baseurl):
    page = requests.get(baseurl + "/simple/")
    tree = html.fromstring(page.content)
    pkgs = tree.xpath("//@href")

    return pkgs


# This function parses the command line arguments
def parseCommandLine():
    parser = argparse.ArgumentParser(description="Script to mirror pypi packages")
    parser.add_argument('-m', dest='mirror_tld', default='/mirror1/repos', help='Base directory to store repos')
    parser.add_argument('-r', dest='repo_name', help='repo name for storing packages in', required=True)
    parser.add_argument('-c', dest='config_file', type=argparse.FileType('r'), help='file to parse packages name to download')
    parser.add_argument('-u', dest='repo_url', default='https://pypi.org', help='URL of pypi index site')

    args = parser.parse_args()

    return args


def processPackageIndex(pkg):
    # Here we look for the simple package name for the package item
    # returned in package list
    pkg_name_match = re.search(r"simple/(.*)/", pkg, re.IGNORECASE)
    if pkg_name_match:
        pkg_name = pkg_name_match.group(1)
    else:
        pkg_name = pkg

    page = requests.get(repo_url + "/simple/" + pkg_name)
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
    save_loc = simple_loc + "/" + pkg_name
    os.makedirs(save_loc, exist_ok=True)
    doc.write(save_loc + "/" + "index.html")

    return pkg_name


def processPackageFiles(pkg_name):

    # Here we get the json info page for the package
    page = requests.get(repo_url + "/pypi/" + pkg_name + "/json")
    if page.status_code == 200:
        json_page = page.json()

        if len(json_page['releases']) > 0:
            for release in json_page['releases']:
                if len(json_page['releases'][release]) > 0:
                    for file in json_page['releases'][release]:
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
                                print("[INFO]: Downloading " + file_name + "...")
                                os.makedirs(file_dir, exist_ok=True)  # create (if not existing) path to file to be saved
                                package_file_req = requests.get(file_url, stream=True)
                                with open(file_loc, 'wb') as outfile:
                                    shutil.copyfileobj(package_file_req.raw, outfile)
                                os.utime(file_loc, (file_url_time_epoch, file_url_time_epoch))
                            else:
                                print("[INFO]: " + file_name + " exists, skipping...")

                        else:
                            print("[WARN]: No package file url matched, skipping...")
                            continue


######################################### Start of main processing

if __name__ == "__main__":

    args = parseCommandLine()

    mirror_tld = args.mirror_tld
    repo_name = args.repo_name
    repo_url = args.repo_url
    web_loc = mirror_tld + "/" + repo_name + "/" + "web"
    simple_loc = web_loc + "/" + "simple"

    if args.config_file is None:
        print("[INFO]: No list of packages specified, downloading from pypi index: " + repo_url)
        pkgs = getPackageList(repo_url)
    else:
        pkgs = args.config_file.read().split()

    for p in pkgs:
        pkg_simple_name = processPackageIndex(p)
        print("[INFO]: Processing package " + pkg_simple_name + "...")
        processPackageFiles(pkg_simple_name)
