gtk_dep = dependency('gtk4', version: '>=4.6')
granite_dep = dependency('granite-7', version: '>=7.0')
gee_dep = dependency('gee-0.8')

executable(
  meson.project_name(),
  [
    'Application.vala',
    'MainWindow.vala',
    'Scanner.vala',
    'Cleaner.vala',
    'CleaningTarget.vala',
    'GroupSelectionBatch.vala',
    'FileUtils.vala',
    'Preferences.vala',
    'ScanOptionGroups.vala',
    'Stats.vala'
  ],
  dependencies: [gtk_dep, granite_dep, gee_dep],
  c_args: [
    '-DGETTEXT_PACKAGE="@0@"'.format(gettext_package),
    '-DLOCALEDIR="@0@"'.format(locale_dir)
  ],
  vala_args: [
    '--target-glib=2.72'
  ],
  install: true,
  install_dir: get_option('bindir')
)
