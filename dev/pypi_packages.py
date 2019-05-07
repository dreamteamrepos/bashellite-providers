from lxml import html, etree
import requests, re, argparse, os, datetime, shutil, logging, sys


# This function grabs a list of all the packages at the pypi index site specified by 'baseurl'
def getPackageListFromIndex(baseurl):
    page = requests.get(baseurl + "/simple/")
    tree = html.fromstring(page.content)
    pkgs = tree.xpath("//@href")

    newpkgs = []

    for p in pkgs:
        # Here we look for the simple package name for the package item
        # returned in package list
        pkg_name_match = re.search(r"simple/(.*)/", p, re.IGNORECASE)
        if pkg_name_match:
            tmp = pkg_name_match.group(1)
            newpkgs.append(tmp)
        else:
            newpkgs.append(p)

    return newpkgs


# This function parses the command line arguments
def parseCommandLine():
    parser = argparse.ArgumentParser(
        description="Script to download list of packages from a pypi index"
        )
    parser.add_argument('-u', dest='repo_url', default='https://pypi.org', help='URL of pypi index site')

    args = parser.parse_args()

    return args

######################################### Start of main processing

if __name__ == "__main__":
    
    logging.basicConfig(level=logging.INFO, format='[%(levelname)s]: %(message)s')
    args = parseCommandLine()

    repo_url = args.repo_url

    pkgs = getPackageListFromIndex(repo_url)

    for pkg_name in pkgs:
        print(pkg_name)
