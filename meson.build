project(
  'purrify',
  ['vala', 'c'],
  version: '1.0.6',
  license: 'GPL-3.0-or-later',
  meson_version: '>=0.61.0'
)

i18n = import('i18n')
gnome = import('gnome')

app_id = 'io.github.alessandro_mattos.purrify'
gettext_package = 'purrify'
locale_dir = join_paths(get_option('prefix'), get_option('localedir'))

subdir('src')
subdir('data')
subdir('po')
subdir('tests')
