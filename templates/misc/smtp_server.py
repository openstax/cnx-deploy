#!/usr/bin/env python

# A smtp server that uses e-mail-tester.appspot.com api to send
# emails.

# Based on https://djangosnippets.org/snippets/96/

import asyncore
import datetime
import email
import json
from smtpd import SMTPServer
import urllib2

EMAIL_API_KEY = '{{ email_api_key }}'

def _get_content(mail):
    text = ''
    html = ''              
    if mail.is_multipart():            
        for part in mail.get_payload():                           
            if part.get_content_type() == 'multipart/alternative':
                return self._get_content(part)
                                                  
            if part.get_content_charset() is None:
                continue                        
            charset = part.get_content_charset()
                                                                      
            _text = part.get_payload(decode=True).decode(str(charset))
            if part.get_content_type() == 'text/plain':
                text = _text                            
            elif part.get_content_type() == 'text/html':
                html = _text
    else:                                           
        text = mail.get_payload(decode=True).decode(
            str(mail.get_content_charset()))
    return text, html


class MySMTPServer(SMTPServer):
    def process_message(self, peer, mailfrom, rcpttos, data):
        # peer: ('127.0.0.1', 33360) mailfrom: 'noreply@example.com' rcpttos: ['karen@example.com']
        message = email.message_from_string(data)
        subject = message.get('Subject')
        text, html = _get_content(message)
        data = json.dumps({
            'to': rcpttos,
            'subject': subject,
            'body': text,
            'html': html})
        req = urllib2.Request(
            'https://e-mail-tester.appspot.com/send-mail/{}'
                .format(EMAIL_API_KEY),
            data,
            {'Content-Type': 'application/json'})
        with open('smtpd.log', 'a') as f:
            f.write('{} To: {} Subject: {} Response: {}\n'.format(
                datetime.datetime.now().isoformat(),
                rcpttos,
                subject,
                urllib2.urlopen(req).read()))


def run():
    server = MySMTPServer(('localhost', 25), None)
    try:
        asyncore.loop()
    except KeyboardInterrupt:
        pass

if __name__ == '__main__':
    run()
