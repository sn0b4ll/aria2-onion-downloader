#!/usr/bin/env python3
"""\
Heavily modified based on the original script by @mai-gh
https://github.com/mai-gh/get_tor_ua

This script fetches the default branch of the Tor Browser GitLab repository,
retrieves the latest milestone version, and constructs a User-Agent string
based on the values found in the repository. It then updates aria2.conf with the new User-Agent string.
"""
import urllib.request
import json
import re
import sys

hdrs = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:128.0) Gecko/20100101 Firefox/128.0',
  'Accept-Encoding': 'gzip, deflate, br'
}

url_base = 'https://gitlab.torproject.org/tpo/applications/tor-browser'
project_path_encoded = urllib.parse.quote_plus('tpo/applications/tor-browser')
api_url = f'https://gitlab.torproject.org/api/v4/projects/{project_path_encoded}'

branch = None

try:
    with urllib.request.urlopen(urllib.request.Request(method='GET', url=api_url, headers=hdrs)) as response:
        if response.status == 200:
            project_data = json.load(response)
            branch = project_data.get('default_branch')
            if not branch:
                print("Error: Could not find 'default_branch' in API response.")
                sys.exit(1)
        else:
            print(f"Error: API request failed with status {response.status}")
            print(response.read().decode())
            sys.exit(1)

except urllib.error.URLError as e:
    print(f"Error: Could not connect to GitLab API: {e}")
    sys.exit(1)
except json.JSONDecodeError as e:
    print(f"Error: Could not decode JSON response from API: {e}")
    sys.exit(1)
except KeyError:
    print("Error: 'default_branch' key not found in the API response.")
    sys.exit(1)

print(f"Successfully fetched default branch: {branch}")

# this logic comes from ./build/moz.configure/init.configure
try:
    milestone_url = url_base + '/-/raw/' + branch + '/config/milestone.txt'
    with urllib.request.urlopen(urllib.request.Request(method='GET', url=milestone_url, headers=hdrs)) as response:
      milestone_lines = [l.decode().strip() for l in response.readlines()]
      last_milestone_line = next((line for line in reversed(milestone_lines) if line), None)

      if last_milestone_line:
          spoofed_version = last_milestone_line.split(".")[0]
          if not spoofed_version.isdigit():
              print(f"Warning: Extracted spoofed_version '{spoofed_version}' is not purely numeric.")
      else:
          print("Error: Could not find a valid version line in milestone.txt.")
          sys.exit(1)

    rfph_url = url_base + '/-/raw/' + branch + '/toolkit/components/resistfingerprinting/nsRFPService.h'
    with urllib.request.urlopen(urllib.request.Request(method='GET', url=rfph_url, headers=hdrs)) as response:
      rfph_raw = response.read().decode()
      spoofed_ua_os_lines = [ l for l in rfph_raw.splitlines() if '#  define SPOOFED_UA_OS' in l]
      gecko_trail_lines = [ l for l in rfph_raw.splitlines() if '#define LEGACY_UA_GECKO_TRAIL' in l]

      if not spoofed_ua_os_lines:
          print("Error: Could not find '#  define SPOOFED_UA_OS' in nsRFPService.h")
          sys.exit(1)
      if not gecko_trail_lines:
          print("Error: Could not find '#define LEGACY_UA_GECKO_TRAIL' in nsRFPService.h")
          sys.exit(1)

      try:
          spoofed_ua_os = spoofed_ua_os_lines[0].split('"')[1]
          gecko_trail = gecko_trail_lines[0].split('"')[1]
      except IndexError:
           print("Error: Could not parse SPOOFED_UA_OS or LEGACY_UA_GECKO_TRAIL from nsRFPService.h")
           sys.exit(1)

except urllib.error.URLError as e:
    print(f"Error: Could not fetch remote files (milestone.txt or nsRFPService.h): {e}")
    sys.exit(1)
except Exception as e:
    print(f"An unexpected error occurred while processing remote files: {e}")
    sys.exit(1)

# Example: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:128.0) Gecko/20100101 Firefox/128.0
try:
    user_agent_string = "Mozilla/5.0 (%s; rv:%d.0) Gecko/%d Firefox/%d.0" % (spoofed_ua_os, int(spoofed_version), int(gecko_trail), int(spoofed_version))
    print(f"Constructed User-Agent: {user_agent_string}")
except ValueError as e:
    print(f"Error: Could not format User-Agent string: {e}")
    sys.exit(1)
except IndexError as e:
    print(f"Error constructing user agent string. Check fetched values. {e}")
    sys.exit(1)

conf_file_path = "/conf/aria2.conf"
conf_content = ""

try:
    with open(conf_file_path, "r") as file:
        conf_content = file.read()
except FileNotFoundError:
    print(f"Error: Configuration file '{conf_file_path}' not found.")
    sys.exit(1)
except IOError as e:
    print(f"Error: Could not read configuration file '{conf_file_path}': {e}")
    sys.exit(1)

target_ua_line_content = f'user-agent={user_agent_string}'
regex_pattern = r"user-agent=.*"

existing_ua_match = re.search(regex_pattern, conf_content)

if existing_ua_match:
    existing_ua_line = existing_ua_match.group(0).strip()
    if existing_ua_line == target_ua_line_content:
        print(f"User-Agent in '{conf_file_path}' already matches '{user_agent_string}'. No changes needed.")
        sys.exit(0)
    else:
        print(f"Existing User-Agent '{existing_ua_line}' found, but needs updating.")
else:
    print("No existing User-Agent line found in the configuration file.")

updated_conf_content, num_subs = re.subn(regex_pattern, target_ua_line_content, conf_content, count=1)

if num_subs > 0:
    print(f"Replaced User-Agent in {conf_file_path}: {user_agent_string}")
else:
    if conf_content:
        if not conf_content.endswith("\n"):
            updated_conf_content = conf_content + "\n" + target_ua_line_content
            print(f"Added User-Agent to {conf_file_path}: {user_agent_string}")
        else:
            updated_conf_content = conf_content + target_ua_line_content
            print(f"Added User-Agent to {conf_file_path}: {user_agent_string}")
    else:
        print(f"File is empty or does not exist! Please check the file path: {conf_file_path}")

if updated_conf_content and not updated_conf_content.endswith("\n"):
    updated_conf_content += "\n"
elif not updated_conf_content and target_ua_line_content:
     pass

try:
    with open(conf_file_path, "w") as file:
        file.write(updated_conf_content)
except IOError as e:
    print(f"Error: Could not write to configuration file '{conf_file_path}': {e}")
    sys.exit(1)
except Exception as e:
    print(f"Unexpected error: {e}")
    sys.exit(1)

print(f"Changes Written Successfully to {conf_file_path}")
sys.exit(0)
