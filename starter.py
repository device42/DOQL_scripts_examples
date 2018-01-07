# encoding: utf-8

import os
import ssl
import sys
import csv
import json
import time
import base64

from datetime import datetime
from datetime import timedelta

try:
    import pyodbc
except ImportError:
    pass

# PYTHON 2 FALLBACK #

try:
    from urllib.request import urlopen, Request
    from urllib.parse import urlencode
    from io import StringIO
    python = 3
except ImportError:
    from urllib import urlencode
    from urllib2 import urlopen, Request
    from StringIO import StringIO
    reload(sys)  
    sys.setdefaultencoding('utf8')
    python = 2

# PYTHON 2 FALLBACK #

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

global _debug
_debug = True


def _post(url, query, options):

    # PYTHON 2 FALLBACK #

    if python == 3:
        base64string = base64.b64encode(bytes('%s:%s' % (options['username'], options['password']), 'utf-8'))
        post_data = bytes(urlencode({
            "query": query,
            "header": "yes"
        }), 'utf-8')
    else:
        base64string = base64.b64encode('%s:%s' % (options['username'], options['password']))
        post_data = urlencode({
            "query": query,
            "header": "yes"
        })

    # PYTHON 2 FALLBACK #

    request = Request(url, post_data)
    request.add_header("Authorization", "Basic %s" % base64string.decode("utf-8"))
    request.get_method = lambda: 'POST'
    r = urlopen(request, context=ctx)
    body = r.read()
    r.close()

    if _debug:
        msg = 'Status code: %s' % str(r.code)

        print('\n\t----------- POST FUNCTION -----------')
        print('\t' + url)
        print('\t' + msg)
        print('\tQuery: ' + query)
        print('\t------- END OF POST FUNCTION -------\n')

    return body


def get_list_from_csv(text):
    f = StringIO(text.decode("utf-8"))
    list_ = []
    dict_reader = csv.DictReader(f, quotechar='"', delimiter=',', quoting=csv.QUOTE_ALL, skipinitialspace=True, dialect='excel')
    for item in dict_reader:
        list_.append(item)

    return list_, [x for x in dict_reader.fieldnames]


def doql_call(config, query):

    limit = 0
    query['query'] = ' '.join(query['query'].split()).lower()

    # prepare date-filtered query
    if query['date'] and query['date']['column'] and query['date']['days_limit']:
        index = None
        where_index = query['query'].find('where')
        order_index =  query['query'].find('order by')

        if where_index > 0:
            index = where_index + 6
            query['query'] = query['query'][:index] + " %s > current_date - interval '%s day' and " % (query['date']['column'], query['date']['days_limit']) + query['query'][index:]
        elif order_index > 0:
            index = order_index
            query['query'] = query['query'][:index] + " where %s > current_date - interval '%s day' " % (query['date']['column'], query['date']['days_limit']) + query['query'][index:]

    if query['output_format'] == 'csv' or query['output_format'] == 'json':
        if query['offset']:
            page = 0
            _next = True
            while _next:

                doql_offset = page * query['offset']
                doql_limit = query['offset']

                if query['limit'] and query['limit'] > query['offset']:
                    if (doql_offset + query['offset']) > query['limit']:
                        doql_limit = query['limit'] - doql_offset
                else:
                    if query['limit']:
                        doql_limit = query['limit']

                doql_query = query['query'] + ' LIMIT %s OFFSET %s' % (doql_limit, doql_offset)

                res = _post(
                    'https://%s/services/data/v1.0/query/' % config['host'], doql_query, {
                        'username': config['username'],
                        'password': config['password']
                    }
                )
                csv_list, field_order = get_list_from_csv(res)

                if query['output_format'] == 'csv':
                    file = open('%s_%s_%s.csv' % (query['output_filename'], time.strftime("%Y%m%d%H%M%S"), page + 1 ), 'w+')
                    file.write(res.decode("utf-8"))
                elif query['output_format'] == 'json':
                    file = open('%s_%s_%s.json' % (query['output_filename'], time.strftime("%Y%m%d%H%M%S"), page + 1), 'w+')
                    file.write(json.dumps(csv_list, indent=4, sort_keys=True))

                if doql_limit != query['offset'] or len(csv_list) != query['offset'] or (doql_offset + doql_limit) == query['limit'] :
                    break

                page += 1

        else:

            if query['limit']:
                doql_query = query['query'] + ' LIMIT %s ' % query['limit']
            else:
                doql_query = query['query']

            res = _post(
                'https://%s/services/data/v1.0/query/' % config['host'], doql_query, {
                    'username': config['username'],
                    'password': config['password']
                }
            )
            csv_list, field_order = get_list_from_csv(res)

            if query['output_format'] == 'csv':
                file = open('%s_%s.csv' % (query['output_filename'], time.strftime("%Y%m%d%H%M%S")), 'w+')
                file.write(res)
            elif query['output_format'] == 'json':
                csv_list, field_order = get_list_from_csv(res)
                file = open('%s_%s.json' % (query['output_filename'], time.strftime("%Y%m%d%H%M%S")), 'w+')
                file.write(json.dumps(csv_list, indent=4, sort_keys=True))

        file.close()

    elif query['output_format'] == 'database':

        if query['limit']:
            doql_query = query['query'] + ' LIMIT %s ' % query['limit']
        else:
            doql_query = query['query']

        res = _post(
            'https://%s/services/data/v1.0/query/' % config['host'], doql_query, {
                'username': config['username'],
                'password': config['password']
            }
        )
        csv_list, field_order = get_list_from_csv(res)

        cnxn = pyodbc.connect(query['connection_string'], autocommit=True)
        conn = cnxn.cursor()

        for record in csv_list:
            # some special cases for strange DOQL responses ( that may break database such as MySQL )
            query_str = "INSERT INTO %s (%s) VALUES (%s)" % (query['table'], ','.join(field_order), ','.join([str("'%s'" % record[x][:-1].replace("'", "\\'")) if record[x].endswith('\\') else str("'%s'" % record[x].replace("'", "\\'")) for x in record]))
            conn.execute(query_str)

        print("Added %s records" % len(csv_list))

        conn.close()


def main():
    try:
        with open('settings.json') as data_file:
            config = json.load(data_file)
    except IOError:
        print('File "settings.json" doesn\'t exists.')
        sys.exit()

    try:
        with open(sys.argv[1]) as data_file:
            query = json.loads(data_file.read().replace('\n', '').replace("  ", ' '))
    except IOError:
        print('File "%s" doesn\'t exists.' % sys.argv[1])
        sys.exit()
    doql_call(config, query)

if __name__ == "__main__":

    if len(sys.argv) < 2:
        print('Please use "python starter.py query.json".')
        sys.exit()

    main()
    print('Done!')
    sys.exit()
