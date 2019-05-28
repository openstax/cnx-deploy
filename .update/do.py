import click
import requests
from pathlib import Path

from cnxcommon import ident_hash


here = Path(__file__).parent
CNX_HOST = 'archive.cnx.org'
MAP_FILEPATH = here.resolve().parent / 'roles/webview/files/etc/nginx/uri-maps/rex-uris.map'


def get_rex_release_json_url(host):
    return f'https://{host}/rex/release.json'


def get_book_slug(book_id):
    url = (
        "https://openstax.org/apps/cms/api/v2/pages/"
        f"?type=books.Book&fields=cnx_id&format=json&cnx_id={book_id}"
    )
    book = requests.get(url).json()['items'][0]
    return book['meta']['slug']


def flatten_tree(tree):
    """Flatten a tree to a linear sequence of values."""
    yield dict([
        (k, v)
        for k, v in tree.items()
        if k != 'contents'
    ])
    if 'contents' in tree:
        for x in tree['contents']:
            for y in flatten_tree(x):
                yield y


def rex_uri(book, page):
    if page is None:
        uri = f'/books/{book}'
    else:
        uri = f'/books/{book}/pages/{page}'
    return uri


def cnx_uri_regex(book, page):
    if page is None:
        uri_regex = f"/contents/({book['id']}|{book['short_id']})(@[.\d]+)?(/[-%\w\d]+)?$"
    else:
        uri_regex = f"/contents/({book['id']}|{book['short_id']})(@[.\d]+)?:({page['id']}|{page['short_id']})(@[\d]+)?(/[-%\w\d]+)?$"
    return uri_regex


def expand_tree_node(node):
    result = {
        'slug': node['slug'],
        'title': node['title'],
    }
    result['id'], result['version'] = ident_hash.split_ident_hash(node['id'])
    try:
        # We raise an error for this... It maybe makes sense for the application of it in archive?
        ident_hash.split_ident_hash(node['shortId'])
    except ident_hash.IdentHashShortId as exc:
        result['short_id'] = exc.id
    return result


def get_book_nodes(book_id):
    """Returns a list of nodes in a book's tree."""
    resp = requests.get(f'https://{CNX_HOST}/contents/{book_id}.json')
    metadata = resp.json()
    book_short_id = metadata
    for x in flatten_tree(metadata['tree']):
        yield expand_tree_node(x)


def generate_nginx_uri_mappings(book):
    """\
    This creates the nginx uri map to be used inside the nginx
    configuration's `map` block.

    """
    nodes = list(get_book_nodes(book))
    book_node = nodes[0]
    book_slug = get_book_slug(book)

    uri_mappings = [
        # Book URL redirects to the first page of the REX book
        (cnx_uri_regex(book_node, None), rex_uri(book_slug, nodes[1]['slug']),)
    ]
    for node in nodes[1:]:  # skip the book
        uri_mappings.append(
            (cnx_uri_regex(book_node, node),
             rex_uri(book=book_slug, page=node['slug']),
            )
        )
    return uri_mappings


def write_nginx_map(uri_map, out):
    for orig_uri, dest_uri in uri_map:
        out.write(f'~{orig_uri}    {dest_uri};\n'.encode())


@click.command()
@click.argument('rex-host')
def update_rex_redirects(rex_host):
    release_json_url = get_rex_release_json_url(rex_host)
    release_data = requests.get(release_json_url).json()
    books = [book for book in release_data['books']]
    if MAP_FILEPATH.exists():
        click.echo("Removing existing map")
        MAP_FILEPATH.unlink()
    for book in books:
        click.echo(f"Write entries for {book}.")
        book_uri_map = generate_nginx_uri_mappings(book)
        with MAP_FILEPATH.open('ab') as fb:
            write_nginx_map(book_uri_map, out=fb)


def generate_cnx_uris(book_id):
    """\
    Generates a list of URIs for a cnx book. The URIs are several variations
    of the same page. This includes URIs with and without versions
    that use both the long and short id as well as the combination of the two.

    """
    nodes = list(get_book_nodes(book_id))
    book_node = nodes[0]

    short_book_id = book_node['short_id']

    for node in nodes[1:]:  # skip the book
        # Non-versioned URIs
        yield f"/contents/{book_id}:{node['id']}/{node['slug']}"
        yield f"/contents/{book_id}:{node['short_id']}/{node['slug']}"
        yield f"/contents/{book_node['short_id']}:{node['id']}/{node['slug']}"
        yield f"/contents/{book_node['short_id']}:{node['short_id']}/{node['slug']}"
        # Partial versioned URIs
        yield f"/contents/{book_id}@1.1:{node['id']}/{node['slug']}"
        yield f"/contents/{book_id}@2.99:{node['short_id']}/{node['slug']}"
        yield f"/contents/{book_node['short_id']}@15.123:{node['id']}/{node['slug']}"
        yield f"/contents/{book_node['short_id']}@0.0:{node['short_id']}/{node['slug']}"
        # Fully versioned URIs
        yield f"/contents/{book_id}@1.1:{node['id']}@2/{node['slug']}"
        yield f"/contents/{book_id}@2.99:{node['short_id']}@0/{node['slug']}"
        yield f"/contents/{book_node['short_id']}@15.123:{node['id']}@999/{node['slug']}"
        yield f"/contents/{book_node['short_id']}@0.0:{node['short_id']}@654321/{node['slug']}"




@click.command()
@click.argument('rex-host')
def generate_cnx_uris_for_rex_books(rex_host):
    """This outputs a list of CNX URIs to stdout.
    These are URIs that should redirect to REX.

    The URIs output by this function are intended for testing use.
    They exercise a number of variations the URI can be represented as.

    """
    release_json_url = get_rex_release_json_url(rex_host)
    release_data = requests.get(release_json_url).json()
    for book in release_data['books']:
        for uri in generate_cnx_uris(book):
            click.echo(uri)


@click.group()
def main():
    pass


main.add_command(update_rex_redirects)
main.add_command(generate_cnx_uris_for_rex_books)


if __name__ == '__main__':
    main()
