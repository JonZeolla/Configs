# How to setup Let's Encrypt
## Official Help Article
The official GoDaddy help article is available [here](https://www.godaddy.com/help/install-a-lets-encrypt-ssl-apache-20245).  However, it assumes you have `sudo` or `su` access.
## Instructions for GoDaddy Ultimate Linux Hosting with cPanel
Everything below uses the `letsencrypt` folder as a working area, `websitefolder` for the actual website folder under `~/www`, and `example.com` for the domain, but feel to substitute those with whatever you'd like for your situation.

At some point I may just fork diafygi/letsencrypt-nosudo and PR a branch that handles this, if I get a chance.

1.  Read https://github.com/diafygi/letsencrypt-nosudo/blob/master/README.md first
1.  Open two ssh sessions as the same user
1.  In the first ssh session, generate your private key and csr

    ```
    mkdir ~/letsencrypt # Optional, feel free to substitute your own folders
    cd ~/letsencrypt
    openssl genrsa 4096 > letsencrypt.key
    openssl rsa -in letsencrypt.key -pubout > letsencrypt.pub
    wget https://raw.githubusercontent.com/JonZeolla/Development/master/Bash/generate_csr.sh # Feel free to do this manually or use whatever other method
    # If you use generate_csr.sh, you need to `vi generate_csr.sh` and look for "TODO" fields that need modified.
    chmod 0755 generate_csr.sh
    ./generate_csr.sh
    ```
1.  In the first ssh session, run https://github.com/diafygi/letsencrypt-nosudo/blob/master/sign_csr.py by doing something like:

    ```
    cd ~/letsencrypt
    wget https://raw.githubusercontent.com/diafygi/letsencrypt-nosudo/master/sign_csr.py
    python sign_csr.py --public-key ~/letsencrypt/letsencrypt.pub ~/letsencrypt/example.com.csr > ~/letsencrypt/example.com.crt # Change example.com to the domain you generated earlier
    ```
1.  In the second ssh session, perform step 2.  It should be something like:

    ```
    cd ~/letsencrypt
    openssl dgst -sha256 -sign letsencrypt.key -out register_NS8wfl.sig register_oE09ho.json
    openssl dgst -sha256 -sign letsencrypt.key -out domain_O38YZ8.sig domain_thxMZA.json
    openssl dgst -sha256 -sign letsencrypt.key -out cert_U7jWXQ.sig cert_wgV1LP.json
    ```
1.  Hit enter in the first ssh session.
1.  In the second ssh session, perform step 3.  It should be something like:

    ```
    openssl dgst -sha256 -sign letsencrypt.key -out challenge_rPzEg6.sig challenge_qHbQ3_.json
    ``` 
1.  Hit enter in the first ssh session.
1.  During step 4, instead of following the instructions, run a modified version of:

    ```
    string=RFDD854SyYfWgCRFrIg0XnL3ur9GADDr50-_CIIbP-A.eriaE2ylcU0MoLMhLQFlnhikQeoy3OnaWoqqhoGMKJ8
    mkdir -p ~/www/websitefolder/.well-known/acme-challenge # Change websitefolder to the correct folder
    echo ${string} > ~/www/websitefolder/.well-known/acme-challenge/$(echo ${string} | cut -f1 -d\.) # Change websitefolder to the correct folder
    unset string
    ```
Where RF...J8 is the output of `sign_csr.py` on step 4 r.wfile.write('__HERE__')
1.  After the script has run successfully, **immediately run the following to clean things up**:

    ```
    rm -rf ~/www/websitefolder/.well-known/ # Change websitefolder to the correct folder
    ```
