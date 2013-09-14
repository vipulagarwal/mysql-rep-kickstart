#!/usr/bin/perl

# MySQL replication kickstart script - Version 1.0
# This script can be used to kickstart repliction on a MySQL slave server
# For details, please check the README document
# Copyright (C) 2013 Vipul Agarwal - vipul@nuttygeeks.com
#
# For latest update, please check the github repository
# available at https://github.com/toxboi/mysql-rep-kickstart
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

use Term::ANSIColor qw(:constants);

sub FILTER_QUERY
{
	my($text) = @_;
	
	# Find where faulty query starts and ends
	my $start_point = rindex( $text, "Query: ");
	my $end_point = index( $text, "Replicate_Ignore_Server_Ids:");
	
	# Filtering query and removing unwanted text
	my $query = substr( $text, $start_point + 8, $end_point - $start_point - 12);
	$query =~ s/`//g;
	
	# Completing the query with necessary commands
	$query = "USE gk_live; $query; SET GLOBAL SQL_SLAVE_SKIP_COUNTER = 1; START SLAVE;";	
	
#	print "\n$query\n";	
	return $query;	
}

sub CHECK_REPLICATION
{
	my($text,$temp) = @_;	
	
	#print $text;		
	
	my $flag = index( $text, "Seconds_Behind_Master: NULL");
	
	if($flag != -1)
	{
		print RED, "\nReplication is broken!\n", RESET;
		print BLUE, "\nFixing..\n", RESET;
		print `mysql -e "$query"`;
		return 1;				
	}
	else
	{
		if(defined($temp))
		{
			print GREEN, "\nReplication is working!\n", RESET;
			return 0;		
		}
		else
		{
				# Wait for any near future faulty transactions
				sleep 10;
				$text = `mysql -e "SHOW SLAVE STATUS\\G"`;
				CHECK_REPLICATION($text,1)
		}			
	}	
}

do
{	
	#Check if replication is working
	my $text = `mysql -e "SHOW SLAVE STATUS\\G"`;
	$isReplicationNULL = CHECK_REPLICATION($text);
	
} while $isReplicationNULL == 1;
