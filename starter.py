# encoding: utf-8

import os
import ssl
import sys
import csv
import json
import time
import urllib
import urllib2
import base64
import StringIO
from datetime import datetime
from datetime import timedelta

reload(sys)  
sys.setdefaultencoding('utf8')

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

global _debug
_debug = True


def _post(url, query, options):

    request = urllib2.Request(url, urllib.urlencode({
        "query": query,
        "header": "yes"
    }))
    base64string = base64.b64encode('%s:%s' % (options['username'], options['password']))
    request.add_header("Authorization", "Basic %s" % base64string)
    request.get_method = lambda: 'POST'
    r = urllib2.urlopen(request, context=ctx)
    body = r.read()
    r.close()

    if _debug:
        msg = 'Status code: %s' % str(r.code)

        print '\n\t----------- POST FUNCTION -----------'
        print '\t' + url
        print '\t' + msg
        print '\t Query: ' + query
        print '\t------- END OF POST FUNCTION -------\n'

    return body


def get_list_from_csv(text):
    f = StringIO.StringIO(text.encode('utf-8'))
    list_ = []
    dict_reader = csv.DictReader(f, quotechar='"', delimiter=',', quoting=csv.QUOTE_ALL, skipinitialspace=True, dialect='excel')
    for item in dict_reader:
        list_.append(item)

    return list_, [x for x in dict_reader.fieldnames]


def doql_call(config, query):

    query['query'] = ' '.join(query['query'].split())

    res = _post(
        'https://%s/services/data/v1.0/query/' % config['host'], query['query'], {
            'username': config['username'],
            'password': config['password']
        }
    )
    csv = res.encode('ascii', 'ignore')

    # prepare date-filtered csv
    if query['date'] and query['date']['column'] and query['date']['days_limit']:
        csv_list, field_order = get_list_from_csv(csv)
        csv = [x for x in csv_list if datetime.strptime(x[query['date']['column']].split(' ')[0], '%Y-%m-%d') > datetime.now() - timedelta(days=query['date']['days_limit'])]
        temp = [','.join(field_order)]

        for x in csv:
            temp.append(','.join(['"%s"' % x[y] for y in field_order]))
        csv = '\n'.join(temp)

    lines = csv.split('\n')
    header = lines.pop(0)

    # check limits
    if query['limit']:
        try:
            lines = lines[:query['limit']]
        except:
            pass

    if query['output_format'] == 'csv':
        if query['offset']:
            pages = (len(lines) / query['offset']) + 2
            for i in range(1, pages):
                file = open('%s_%s_%s.csv' % (query['output_filename'], time.strftime("%Y%m%d%H%M%S"), i), 'w+')
                file.write('\n'.join([header] + lines[(i - 1) * query['offset']:i * query['offset']]))
        else:
            file = open('%s_%s.csv' % (query['output_filename'], time.strftime("%Y%m%d%H%M%S")), 'w+')
            file.write(csv)
    else:
        if query['offset']:
            pages = (len(lines) / query['offset']) + 2
            for i in range(1, pages):
                file = open('%s_%s_%s.json' % (query['output_filename'], time.strftime("%Y%m%d%H%M%S"), i), 'w+')
                csv_list, field_order = get_list_from_csv('\n'.join([header] + lines[(i - 1) * query['offset']:i * query['offset']]))
                file.write(json.dumps(csv_list, indent=4, sort_keys=True))
        else:
            file = open('%s_%s.json' % (query['output_filename'], time.strftime("%Y%m%d%H%M%S")), 'w+')
            csv_list, field_order = get_list_from_csv(csv)
            file.write(json.dumps(csv_list, indent=4, sort_keys=True))

    file.close()


def main():
    try:
        with open('settings.json') as data_file:
            config = json.load(data_file)
    except IOError:
        print 'File "settings.json" doesn\'t exists.'
        sys.exit()

    try:
        with open(sys.argv[1]) as data_file:
            query = json.loads(data_file.read().replace('\n', '').replace("  ", ' '))
    except IOError:
        print 'File "%s" doesn\'t exists.' % sys.argv[1]
        sys.exit()
    doql_call(config, query)

if __name__ == "__main__":

    if len(sys.argv) < 2:
        print 'Please use "python starter.py query.json".'
        sys.exit()

    retval = main()
    print 'Done!'
    sys.exit(retval)
