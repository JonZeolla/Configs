# How to setup Let's Encrypt
## Official Help Article
The official GoDaddy help article is available [here](https://www.godaddy.com/help/install-a-lets-encrypt-ssl-apache-20245).  However, it assumes you have `sudo` or `su` access.
## Instructions for GoDaddy Ultimate Linux Hosting with cPanel
1.  Read https://github.com/diafygi/letsencrypt-nosudo/blob/master/README.md first
1.  Open two ssh sessions
1.  In the first ssh session, run https://github.com/diafygi/letsencrypt-nosudo/blob/master/sign_csr.py by doing something like:

    ```
    cd ~
    mkdir ~/websitefolder
    python sign_csr.py --public-key ~/websitefolder/letsencrypt.pub ~/websitefolder/example.com.csr > ~/websitefolder/example.com.crt
    ```
1.  In the second ssh session, perform step 2.  It should be something like:

    ```
    cd ~
    openssl dgst -sha256 -sign ~/websitefolder/letsencrypt.key -out register_NS8wfl.sig register_oE09ho.json
    openssl dgst -sha256 -sign ~/websitefolder/letsencrypt.key -out domain_O38YZ8.sig domain_thxMZA.json
    openssl dgst -sha256 -sign ~/websitefolder/letsencrypt.key -out cert_U7jWXQ.sig cert_wgV1LP.json
    ```
1.  In the second ssh session, perform step 3.  It should be something like:

    ```
    cd ~
    openssl dgst -sha256 -sign ~/websitefolder/letsencrypt.key -out challenge_rPzEg6.sig challenge_qHbQ3_.json
    ``` 
1.  During step 4, instead of following the instructions, run a modified version of:

    ```
    string=RFDD854SyYfWgCRFrIg0XnL3ur9GADDr50-_CIIbP-A.eriaE2ylcU0MoLMhLQFlnhikQeoy3OnaWoqqhoGMKJ8
    mkdir -p ~/www/websitefolder/.well-known/acme-challenge
    echo ${string} > ~/www/websitefolder/.well-known/acme-challenge/$(echo ${string} | cut -f1 -d\.)
    unset string
    ```
Where RF...J8 is the output of `sign_csr.py` on step 4 r.wfile.write('__HERE__')
1.  After the script has run successfully, run the following to clean things up:

    ```
    cd ~/www/websitefolder/
    rm -rf ~/www/websitefolder/.well-known/
    ```
