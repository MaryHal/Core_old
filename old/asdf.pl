#!/usr/bin/env perl
# Class Opening Reminder and Emailer (CORE) v2.0
# By Sanford Lam
# I'm a perl newbie, any help would be much appreciated

use warnings;
use strict;

use Class::Struct;
use Term::ReadKey;

struct LoginInfo =>
{
    user => '$',
    pass => '$',
};

struct Course => 
{
    sln  => '@',
    drop => '@',
};

struct Core =>
{
    info    => 'LoginInfo',
    courses => '@',
    sleep   => '$',
};

sub readLoginDetails
{
=pod
    my $login = shift;

    print "Username: ";
    $user = ReadLine(0);
    chomp $login->user;

    ReadMode('noecho');
    print "Password: ";
    $login->pass = ReadLine(0);
    chomp $login->pass;

    ReadMode('normal');

    print "\n";
=cut
}

sub runCore
{
    my $core = Core->new( info => LoginInfo->new( user => 'asdf', pass => '123'),
                          courses => [],
                          sleep => 30,
    );

    push($core->courses, Course->new(sln => ['a', 'b', 'c'],
                                     drop => ['d', 'e', 'f'],
        )
    );

    print @{$core->courses->[0]->sln};
    print "\n";
    print @{$core->courses->[0]->drop};
    print "\n";

    &readLoginDetails(\$core->info);
}

&runCore

