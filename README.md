# DKIM verification script #

Reporters often need to verify the authenticity of leaked emails, and one
increasingly popular technique is to check those emails' [DKIM signatures][],
as [ProPublica documented so well in 2017][].

The ProPublica post explains how to do this for individual messages, but for
[a recent story][], The Associated Press' investigative team needed to verify
many emails contained in an [mbox][] archive.

[DKIM signatures]: https://en.wikipedia.org/wiki/DomainKeys_Identified_Mail
[ProPublica documented so well in 2017]: https://www.propublica.org/nerds/authenticating-email-using-dkim-and-arc-or-how-we-analyzed-the-kasowitz-emails
[a recent story]: https://apnews.com/d093a02a3d8a4e1b8dc7f5d19475899b
[mbox]: https://en.wikipedia.org/wiki/Mbox

## Usage ##

```
$ ./verify_dkim.sh MBOX_FILE
```

This script will create an output directory called `messages-organized`, with
the following subdirectories:

*   `messages-organized/unsigned` will contain messages that had no DKIM
    signature at all.

*   `messages-organized/signed/unverified` will contain messages that had DKIM
    signatures, but for some reason those signatures could not be verified.
    (This does not necessarily imply forgery; configurations can change over
    time, and some emails servers just don't behave particularly well.)

*   `messages-organized/signed/verified` will contain messages that had DKIM
    signatures that were verified as authentic.

The script also will produce two other outputs:

*   `messages-split` will be a directory containing all of the original emails,
    not organized in any particular way.

*   `messages-organized.zip` will be a zipped archive of the
    `messages-organized` directory, suitable for sending via any appropriate
    medium.

## Other potential formats ##

*   If you have just one message to verify, follow the instructions in
    [ProPublica's 2017 post][].

*   If you have a directory of many individual messages, consider editing this
    script to skip the `git mailsplit` call in the `INITIALIZATION` section.

[ProPublica's 2017 post]: https://www.propublica.org/nerds/authenticating-email-using-dkim-and-arc-or-how-we-analyzed-the-kasowitz-emails

## Dependencies ##

*   [Git][]

*   [dkimpy][] and [dnspython][] Python packages:

    ```
    $ pip install -r requirements.txt
    ```

[Git]: https://git-scm.com/
[dkimpy]: https://launchpad.net/dkimpy
[dnspython]: http://www.dnspython.org/
