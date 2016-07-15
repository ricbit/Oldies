import os
import re
import requests
import sys

LANG = {
    "asm": "13",
    "cc": "44",
    "py": "99",
    "c": "11",
    "java": "10",
    "rb": "17",
    "hs": "21",
    "bf": "12",
    "txt": "62",
    "pl": "3",
    "go": "114"
}

def read_file(filename):
    original = open(filename, 'rt')
    ans = []
    for line in original:
        include = re.search('#include \"([^\"]+)\"', line)
        if not include:
            ans.append(line)
        else:
            ans.extend(open(include.group(1), 'rt').readlines())
    return ''.join(ans)

def get_cookies():
    spoj = requests.get('http://www.spoj.com/').cookies['SPOJ']
    login_url = 'http://www.spoj.com/login/'
    data = {
        'next_raw': '/',
        'autologin': 1,
        'login_user': os.getenv('SPOJ_USER'),
        'password': os.getenv('SPOJ_PASSWORD')
    }
    cookies = {'SPOJ': spoj}
    login = requests.post(
        login_url, data=data, cookies=cookies, allow_redirects=False)
    cookies['autologin_login'] = login.cookies['autologin_login']
    cookies['autologin_hash'] = login.cookies['autologin_hash']
    cookies['captcha'] = 'no'
    return cookies

def submit_file(code, lang, problem, cookies):
    files = {
        'file': (None, problem),
        'lang': (None, lang),
        'problemcode': (None, code),
        'submit': (None, 'Submit!')
    }
    url = 'http://www.spoj.com/submit/complete/'
    headers = {
        'Host': 'www.spoj.com',
        'Origin': 'http://www.spoj.com'
    }
    req = requests.post(url, files=files, cookies=cookies, headers=headers)

def process_file():
    filename = sys.argv[1]
    problem = read_file(filename)
    code, ext = filename.split('.')
    cookies = get_cookies()
    submit_file(code, LANG[ext], problem, cookies)

process_file()
