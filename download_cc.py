import urllib.request

logos = {
    'mastercard': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Mastercard-logo.svg/250px-Mastercard-logo.svg.png',
    'visa': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Visa_Inc._logo.svg/250px-Visa_Inc._logo.svg.png',
    'troy': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/TROY_logo.svg/250px-TROY_logo.svg.png'
}

for name, url in logos.items():
    try:
        print(f'Downloading {name}...')
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            with open(f'assets/images/logos/{name}.png', 'wb') as f:
                f.write(response.read())
        print(f'Success: {name}.png')
    except Exception as e:
        print(f'Failed to download {name}: {e}')
