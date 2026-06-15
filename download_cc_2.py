import urllib.request

logos = {
    'visa': 'https://t2.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=http://www.visa.com.tr&size=256',
    'troy': 'https://t2.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=http://www.troyodeme.com&size=256'
}

for name, url in logos.items():
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            with open(f'assets/images/logos/{name}.png', 'wb') as f:
                f.write(response.read())
        print(f'Success: {name}.png')
    except Exception as e:
        print(f'Failed to download {name}: {e}')
