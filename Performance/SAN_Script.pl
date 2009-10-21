#!/usr/bin/perl

use strict;
my $debug = 1;

my ($arg,@scsi_devices,$tmp);
my ($POWERMT_BIN, $MOUNT_BIN, $SAN_DEV, %data);

$POWERMT_BIN = `which powermt`;
chomp($POWERMT_BIN);
$MOUNT_BIN = `which mount`;
chomp($MOUNT_BIN);
$SAN_DEV="emcpower";

poll_devices(\%data);
                

################################################################################
#####                           SUB FUNCTIONS                              #####
################################################################################

sub poll_devices {
        my $out = shift;
        my @GET_MOUNTS=`mount | grep -i $SAN_DEV | awk '{print \$1 \":\" \$3}'`;

        foreach my $i (0 .. $#GET_MOUNTS) {
                chomp($GET_MOUNTS[$i]);
                my ($fs,$mount) = split /\:/,$GET_MOUNTS[$i],2;
                $fs =~ s|\/dev\/||;
                $fs =~ s|1$||;
                $mount =~ s|^\/||;
                $$out{$fs}{"mount_point"} = $mount;
                # $$out{$fs}{"devices"} = [];

                @scsi_devices = `$POWERMT_BIN display dev=$fs | grep -e "qla" 2>&1 | awk '{print \$3}'`;
                foreach my $i (0 .. $#scsi_devices) {
                        # print "scsi_devices[$i] = $scsi_devices[$i]\n";
                        chomp($scsi_devices[$i]);
                        $$out{$fs}{"devices"}{"$scsi_devices[$i]"} = {};

                        ##### Find the DISK STATS for the SAN devices #####
                        # $tmp = "cat /sys/block/$scsi_devices[$i]/stat | awk '{print \$1 " " \$3 " " \$4 " " \$5 " " \$7 " " \$8}'";
                        # print "TMP = [$tmp]\n";
                        $tmp = `cat /sys/block/$scsi_devices[$i]/stat | awk '{print \$1 " " \$3 " " \$4 " " \$5 " " \$7 " " \$8}'`;
                        chomp($tmp);
                        my ($reads,$sector_reads,$time_read,$writes,$sector_writes,$time_write) = split /\s+/,$tmp,6;
                        # Clean up the results
                        # chomp($time_write);
                        $$out{$fs}{"devices"}{$scsi_devices[$i]}{"reads"} = $reads;
                        $$out{$fs}{"devices"}{$scsi_devices[$i]}{"sector_reads"} = $sector_reads;
                        $$out{$fs}{"devices"}{$scsi_devices[$i]}{"read_time_in_ms"} = $time_read;
                        # $$out{$fs}{"devices"}{$scsi_devices[$i]}{"avg_read_time_in_ms"} = $time_read / $reads;
                        $$out{$fs}{"devices"}{$scsi_devices[$i]}{"writes"} = $writes;
                        $$out{$fs}{"devices"}{$scsi_devices[$i]}{"sector_writes"} = $sector_writes;
                        $$out{$fs}{"devices"}{$scsi_devices[$i]}{"write_time_in_ms"} = $time_write;
                        # $$out{$fs}{"devices"}{$scsi_devices[$i]}{"avg_write_time_in_ms"} = $time_write / $writes;
                } # end foreach
        } # end foreach

        foreach my $i (sort keys %data) {
                $$out{$i}{total_reads} = 0;
                $$out{$i}{total_sector_reads} = 0;
                $$out{$i}{total_read_time_in_ms} = 0;
                $$out{$i}{total_writes} = 0;
                $$out{$i}{total_sector_writes} = 0;
                $$out{$i}{total_write_time_in_ms} = 0;
                foreach my $j (sort keys %{$$out{$i}{"devices"}}) {
                        $$out{$i}{total_reads} += $$out{$i}{"devices"}{$j}{"reads"};
                        $$out{$i}{total_sector_reads} += $$out{$i}{"devices"}{$j}{"sector_reads"};
                        $$out{$i}{total_read_time_in_ms} += $$out{$i}{"devices"}{$j}{"read_time_in_ms"};
                        $$out{$i}{total_writes} += $$out{$i}{"devices"}{$j}{"writes"};
                        $$out{$i}{total_sector_writes} += $$out{$i}{"devices"}{$j}{"sector_writes"};
                        $$out{$i}{total_write_time_in_ms} += $$out{$i}{"devices"}{$j}{"write_time_in_ms"};
                }
        }

        # if ($debug) {
        #       foreach my $i (sort keys %data) {
        #               print "$i\n" .
        #                     ".. mount_point = $$out{$i}{mount_point}\n" .
        #                     ".... total_reads = $$out{$i}{total_reads}\n" .
        #                     ".... total_sector_reads = $$out{$i}{total_sector_reads}\n" .
        #                     ".... total_read_time_in_ms = $$out{$i}{total_read_time_in_ms}\n" .
        #                     ".... total_writes = $$out{$i}{total_writes}\n" .
        #                     ".... total_sector_writes = $$out{$i}{total_sector_writes}\n" .
        #                     ".... total_write_time_in_ms = $$out{$i}{total_write_time_in_ms}\n";
        #               # foreach my $j (sort keys %{$$out{$i}{"devices"}}) {
        #               #       print ".... $j\n";
        #               #       foreach my $k (sort keys %{$$out{$i}{"devices"}{$j}}) {
        #               #               print "...... $k = $$out{$i}{\"devices\"}{$j}{$k}\n";
        #               #       } # end foreach
        #               # } # end foreach
        #       } # end foreach
        # } # end if
} # end poll_devices
