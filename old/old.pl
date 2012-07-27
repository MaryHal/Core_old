#!/usr/bin/env perl
# Class Opening Reminder and Emailer (CORE)
# By Sanford Lam
# I'm a perl newbie, any help would be much appreciated

# Needs:
#   WWW::Mechanize
#   WWW::Scripter
#   Net::SMTP::TLS;
#   LWP::Protocol::https

use warnings;
use strict;

use File::Temp;
use Getopt::Long;

use WWW::Mechanize;
use WWW::Scripter;
use Net::SMTP::TLS;

use Term::ReadKey;

my $sleep = 30;
my $slnFile = '';

# Command Line Options
my $result = GetOptions(
             'sleep=s' => \$sleep,
             'file=s'  => \$slnFile,
             );

&runCore($sleep, $slnFile);

sub runCore
{
    my $sleep = shift;
    my $slnFile = shift;

    my %slnHash = ();
    my %subHash = ();
    my %dropHash = ();

    my $username = '';
    my $password = '';

    &readLoginDetails(\$username, \$password);
    #print "$username\n$password\n";

    &loadSlnFromFile($slnFile, \%slnHash);
    &printInfo($sleep, \%slnHash);

    my $scripter = new WWW::Scripter(
                   max_docs => 1,
                   max_history => 1,
                   agent => 'Linux Mozilla'
                   );

    #$scripter->use_plugin(JavaScript =>
    #      engine  => 'SpiderMonkey',
    #      init    => \&init, # initialisation function
    #);                         # for the JS environment
    #print $scripter->known_agent_aliases();
    $scripter->use_plugin('JavaScript');

    if (keys(%slnHash) == 0)
    {
        print "No SLNs to monitor...";
        return;
    }

    $| = 1;
    while (keys(%slnHash) > 0)
    {
        while (my ($k, $v) = each %slnHash) 
        {
            $scripter->get(&createUrl($v), 'no_cache' => 1);
            my $text = $scripter->content();
            my $status = classStatus($text);

            if ($status eq "Open")
            {
                &sendEmail("$k is open! Attempting to autoregister...");
                &register($scripter, $v, $username, $password);
                delete $slnHash{$k};
            }
            elsif ($status eq "Login")
            {
                print "Attempting to Log In.\n";
                &login($scripter, $username, $password);
                next;
            }

            print "$k ($v): $status\n";

            sleep $sleep;
        }
    }
    #print $scripter->content();
}

# CORE functions
sub login
{
    my $scripter = shift;
    my $username = shift;
    my $password = shift;

    $scripter->submit_form(
        form_name => 'query',
        fields => {
            user => $username,
            pass => $password,
        },
    );
}

sub register 
{
    my $scripter = shift;
    my $sln = shift;
    my $username = shift;
    my $password = shift;

    print "$sln";

    $scripter->get("https://sdb.admin.washington.edu/students/uwnetid/register.asp", 'no_cache' => 1);

    my $text = $scripter->content();

    # Do I need to log in?
    if ($text =~ /The resource you requested requires you to log in with your UW NetID and password/ || 
        $text =~ /session has expired/)
    {
        print "Attempting to Log In.\n";
        &login($scripter, $username, $password);
    }

    $scripter->get("https://sdb.admin.washington.edu/students/uwnetid/register.asp", 'no_cache' => 1);

    print "\tAttempting to autoregister...\n";
    $scripter->submit_form(
        form_name => 'regform',
        fields => {
            sln6 => "$sln",
        },
    );
}

# Utility Functions
sub createUrl
{
    my $baseUrl = "https://sdb.admin.washington.edu/timeschd/uwnetid/sln.asp?";
    my $quarter = "SPR+2012";
    my $sln = $_[0];

    return $baseUrl . "QTRYR=" . $quarter . "&SLN=" . $sln;
}

sub loadSlnFromFile
{
    my $fileHandle = shift;
    my $slnRef = shift;

    if (!$fileHandle)
    {
        return;
    }

    open FILE, "<$fileHandle" or die $!;
    for (<FILE>)
    {
        my @tokens = split(/\s+/, $_);
        $slnRef->{$tokens[0]} = $tokens[1];
    }

    close FILE;
}

sub readLoginDetails
{
    my $username = shift;
    my $password = shift;

    print "Username: ";
    $$username = ReadLine(0);
    chomp $$username;
    ReadMode('noecho');

    print "Password: ";
    $$password = ReadLine(0);
    chomp $$password;
    ReadMode('normal');
    print "\n";
}

sub classStatus
{
    my $text = shift;

    if ($text =~ />\*\* Closed \*\*</) 
    {
        #print "$class is...Closed\n";
        return "Closed";
    }
    elsif ($text =~ /<b>Open<\/b>/) 
    {
        #print "$class is...Open!\n";
        return "Open";
    }
    elsif ($text =~ /Invalid Request/)
    {
        #print "Invalid Request\n";
        return "Invalid Request";
    }
    elsif ($text =~ /Javascript/)
    {
        #print "ERROR: Javascript not enabled?!?!??\n";
        return "Javascript error?";
    }
    elsif ($text =~ /The resource you requested requires you to log in with your UW NetID and password/)
    {
        return "Login";
    }
    elsif ($text =~ /session has expired/)
    {
        return "Login";
    }

    return "??? (Probably Closed)";
} 

sub printInfo
{
    my $sleepInterval = shift;
    my $slnHash = shift;

    # Pretty print the hash, to make sure the user is okay with it or something
    print "\n\nSLN Hash:\n";
    print "---------------------------------------\n";
    foreach my $key (sort keys %{$slnHash})
    {
        print "$key => $slnHash->{$key}\n";
    }
    print "---------------------------------------\n";
    print "Sleep Interval: $sleepInterval\n";
    print "---------------------------------------\n\n";
}

sub sendEmail 
{
    my $message = $_[0];

    my $mailer = new Net::SMTP::TLS(  
        'smtp.gmail.com',  
        Hello    => 'smtp.gmail.com',  
        Port     => 587,  
        User     => 'io.notify',  
        Password => 'rRP5bYak');

    $mailer->mail('io.notify@gmail.com');  
    $mailer->to('2064028328@tmomail.net');  
    $mailer->data;  
    $mailer->datasend("$message");
    $mailer->dataend;  
    $mailer->quit;  

    return;
}

