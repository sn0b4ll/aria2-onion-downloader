from requests_tor import RequestsTor
from bs4 import BeautifulSoup
from socks import SOCKS5Error
from requests.exceptions import ConnectionError, ChunkedEncodingError

import os
import sys

def fetch_file_urls(rt, base_url, path=""):
    """Recursively fetch file URLs from a web server directory listing."""
    url = os.path.join(base_url, path)

    # Ignore TTL and connection errors sometimes caused by the tor connection
    while True:
        try:
            response = rt.get(url)
            break
        except (ConnectionError, ChunkedEncodingError) as e:
            print(f"[-] Received an Proxy error: {e}")
            

    soup = BeautifulSoup(response.text, 'html.parser')

    file_urls = []

    for link in soup.find_all('a'):
        href = link.get('href')

        if href and not href.startswith('../'):
            if href.endswith('/'):
                print(f"[+] Parsing site href: {href}")
                file_urls.extend(fetch_file_urls(rt, base_url, os.path.join(path, href)))
            else:
                file_path = os.path.join(base_url, path, href)
                file_urls.append(file_path)
                with open("aria2_input.txt", "a") as myfile:
                    myfile.write(file_path + "\n")

                

    return file_urls


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python script_name.py <base_url>")
        sys.exit(1)

    base_url = sys.argv[1]

    rt = RequestsTor(tor_ports=(9050,), tor_cport=9051)
    
    file_urls = fetch_file_urls(rt, base_url)

    for file_url in file_urls:
        print(file_url)

