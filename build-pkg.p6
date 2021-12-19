#!/usr/bin/env perl6

my $here = $*PROGRAM-NAME.IO.parent;
my $deb-root = $here.add: 'deb-root';

my $tree-root = $deb-root.add: 'neovim';
my $control-file = $tree-root.add('DEBIAN/control');

my $version = '0.6.0';

run <rm -rf -->, $deb-root.absolute;

$tree-root.mkdir;

my @install-lines = $here.add('build/install_manifest.txt').lines;
for @install-lines -> $line {
  my $src = $line.IO;
  my $dest = $tree-root.add: $src.relative('/');
  say "$src -> $dest";
  $dest.parent.mkdir;
  $src.copy: $dest;
}

my $installed-size-text = (run <du -s -->, $tree-root, :out).out.slurp(:close);
unless ($installed-size-text.match: /\s*(\d+)<|w>.*/) { die("Didn't match") }
my $installed-size = $0;

my $control-content = qq:to/END/;
Package: neovim
Version: $version
Section: custom
Priority: optional
Architecture: arm64
Essential: no
Installed-Size: $installed-size
Maintainer: owen\@owenehealy.com
Description: Unofficial NeoVim ARM64 build
END

$control-file.parent.mkdir;
my $control-fh = open $control-file, :w;
$control-fh.print($control-content);
$control-fh.close;

run <dpkg-deb --build neovim>, cwd => $deb-root;

my $release = q:x/lsb_release -c -s/.trim;

my $deb-source-file = $deb-root.add('neovim.deb');
my $deb-sink-file = $deb-root.add("neovim_{$version}-{$release}_arm64.deb");
$deb-source-file.move($deb-sink-file);
