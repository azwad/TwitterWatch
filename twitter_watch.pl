#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use feature qw (say );
use lib qw (/home/toshi/perl/lib );
use HashDump;
use Scrape2Feed;
use PitInfo;
use AnyEvent;
use Tweet;

my $setting = 'default';
my $pit_account = 'twitter.toshi0104';

my ($username, $password);

($username, $password) = PitInfo->pitinfo(
	$setting, $pit_account,
	$username, $password,
);

my $login_url = 'https://mobile.twitter.com/session/new';
my $target_url = 'https://mobile.twitter.com/Softbank';
my @check_words = ('iPhone 5', 'iPhone5', );

my $twitter = Scrape2Feed->new('site_name' => 'twitter.com');
my $login_opt = { 
	'login_url' => $login_url,
	'fields' => {
		'username' => $username,
		'password' => $password,
	},
};								
$twitter->login($login_opt);
$twitter->url($target_url);

my $cv = AnyEvent->condvar;
#my $count = 0;
my $wait = 0;
my $interval = 30;
my $post_entry;

my $timer; $timer = AE::timer $wait, $interval, sub {

	my $content = $twitter->get_contents(1,1);
	my $count = 0;
	foreach my $container (@{$content->[1]->{container}}){
		last if $count >2;
		my $entry = $container->{entry_content};
		foreach my $rexep (@check_words){
			if ($entry =~ m/$rexep/){
				say "match"; #$entry;
				$post_entry = $entry;
			}else{
				say "not match";
			}	
		}
		++$count;
	}
	
	if (defined $post_entry){
			undef $timer;
			$cv->send;
	}
	warn "interval $interval seconds";
};

$cv->recv;
say $post_entry;
$post_entry =~ s/data-url="(http:\/\/.*?)"/$1/;
my $post_url = $1;

#say $post_url;

my $tweet = Tweet->new();
$tweet->init({'pit_twitter' => 'twitter.toshi0104', 'pit_bitly' => 'bit.ly',});
my $message = 'Sofbank iPhone5の更新きたか';

$tweet->post_tweet($message,$post_url);





