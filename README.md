# Higure.wtf setup
This is a setup script for https://github.com/Higure-wtf/ . It's based on [setup.elixr.host](https://web.archive.org/web/20210713192259/https://setup.elixr.host) and config values are explained in there.
## Warning
I didn't test this, so if you find any bugs, report them in the *Issues* tab or make a pull request with the fix. Thanks!

Also, another notice is that this script uses your Cloudflare email as the email for lets encrypt and also the admin account.
## Running
I recommend following [this guide](https://web.archive.org/web/20210713192259/https://setup.elixr.host/cloudflare-setup/untitled) **before** running this script, but it will ask to do it anyway. 

You can download the script and run it, but a faster way to do it is to run this:

**For me it doesn't work when I curl it for some reason, so you may have to download and run it if you expierience problems.**
```bash
curl "https://raw.githubusercontent.com/GGORG0/higure-wtf-setup/master/setup.sh" | bash
```
**Reminder:** Always check scripts' contents before just piping them into bash!
### Config
When running the script, it will generate a `config` file in the current directory. Fill it out and press enter. 
