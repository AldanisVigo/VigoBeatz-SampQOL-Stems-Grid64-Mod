#!/usr/bin/perl
use strict; use warnings; use JSON::PP; use Digest::SHA qw(sha256_hex); use Compress::Zlib qw(uncompress); use File::Path qw(make_path remove_tree); use File::Copy qw(copy); use File::Basename qw(dirname);
use FindBin; chdir $FindBin::Bin or die $!;
my ($card,$action)=@ARGV; die "Usage: installer-mac.pl CARD INSTALL|RESTORE\n" unless $card && $action && $action =~ /^(INSTALL|RESTORE)$/;
$card =~ s{/$}{}; die "No SampQOL found at SD root\n" unless -f "$card/autorun/mpcqol.so";
sub readb { my ($p)=@_; open my $f,'<:raw',$p or die "$p: $!\n"; local $/; return <$f> }
sub writeb { my ($p,$data)=@_; make_path(dirname($p)); open my $f,'>:raw',$p or die "$p: $!\n"; print $f $data or die $!; close $f or die $! }
sub hashfile { sha256_hex(readb($_[0])) }
my $manifest=decode_json(readb('manifest.json')); my $backup="$card/VigoBeatz-Backup-SampQOL-v0.3.0";
if ($action eq 'RESTORE') { die "Backup missing\n" unless -f "$backup/state.json"; my $state=decode_json(readb("$backup/state.json")); for my $rel (@{$state->{original}}) { writeb("$card/$rel",readb("$backup/original/$rel")) } for my $rel (@{$state->{created}}) { unlink "$card/$rel" or die $! if -f "$card/$rel" } remove_tree($backup); print "Restored originals.\n"; exit 0 }
die "Existing backup detected; restore first\n" if -e $backup;
die "Unsupported SampQOL binary: only exact v0.3.0 accepted\n" unless hashfile("$card/autorun/mpcqol.so") eq $manifest->{stock_sha256};
my %updates;
for my $rel (sort keys %{$manifest->{patches}}) {
 my $meta=$manifest->{patches}{$rel}; my $orig=readb("$card/$rel"); die "Unsupported original $rel\n" unless sha256_hex($orig) eq $meta->{before};
 my $patch=readb("payload/$meta->{payload}"); die "Patch checksum mismatch\n" unless sha256_hex($patch) eq $meta->{payload_sha256};
 my $ops=decode_json(uncompress($patch) // die "Bad patch compression\n"); my $out='';
 for my $op (@$ops) { if ($op->[0] eq 'c') { $out .= substr($orig,$op->[1],$op->[2]) } elsif ($op->[0] eq 'l' || $op->[0] eq 'i') { $out .= pack('H*',$op->[1]) } else { die "Unknown patch opcode\n" } }
 die "Reconstructed checksum mismatch: $rel\n" unless sha256_hex($out) eq $meta->{after}; $updates{$rel}=$out;
}
for my $rel (keys %{$manifest->{files}}) { my $data=readb("payload/new/$rel"); die "Asset mismatch $rel\n" unless sha256_hex($data) eq $manifest->{files}{$rel}; $updates{$rel}=$data }
my $state={original=>[],created=>[],version=>1};
for my $rel (sort keys %updates) { if (-e "$card/$rel") { die "Not a regular file: $rel\n" unless -f "$card/$rel"; push @{$state->{original}},$rel } else { push @{$state->{created}},$rel } }
make_path($backup);
for my $rel (@{$state->{original}}) { writeb("$backup/original/$rel",readb("$card/$rel")) }
writeb("$backup/state.json",encode_json($state));
eval { for my $rel (sort keys %updates) { writeb("$card/$rel",$updates{$rel}); die "Write verification failed: $rel\n" unless hashfile("$card/$rel") eq sha256_hex($updates{$rel}) } };
if ($@) { my $err=$@; for my $rel (@{$state->{original}}) { writeb("$card/$rel",readb("$backup/original/$rel")) } for my $rel (@{$state->{created}}) { unlink "$card/$rel" if -f "$card/$rel" } die "Installation failed, originals restored: $err" }
print "SUCCESS. Mod installed. Backup saved on SD card. Hardware testing still required.\n";
