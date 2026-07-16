app_id = 'io.github.alessandro_mattos.purrify'
icon_source_name = 'io.github.alessandro_mattos.Purrify.svg'

i18n.merge_file(
  input: app_id + '.desktop.in',
  output: app_id + '.desktop',
  type: 'desktop',
  po_dir: '../po',
  install: true,
  install_dir: join_paths(get_option('datadir'), 'applications')
)

i18n.merge_file(
  input: app_id + '.metainfo.xml.in',
  output: app_id + '.metainfo.xml',
  po_dir: '../po',
  install: true,
  install_dir: join_paths(get_option('datadir'), 'metainfo')
)

install_data(
  'icons/hicolor/scalable/apps/' + icon_source_name,
  install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', 'scalable', 'apps'),
  rename: app_id + '.svg'
)

foreach icon_size : ['16x16', '24x24', '32x32', '48x48', '64x64', '128x128']
  install_data(
    'icons/hicolor/' + icon_size + '/apps/' + icon_source_name,
    install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', icon_size, 'apps'),
    rename: app_id + '.svg'
  )
endforeach
