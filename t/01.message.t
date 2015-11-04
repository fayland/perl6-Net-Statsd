use v6;
use Test;
use Net::Statsd;

our $got_message;
class Test::Net::Statsd is Net::Statsd {
    method send_to_socket($message) {
        $got_message = $message;
    }
}

my $statsd = Test::Net::Statsd.new;
$statsd.increment('test.incr');
is $got_message, 'test.incr:1|c', 'increment';

$statsd.increment('test.incr', 2);
is $got_message, 'test.incr:1|c|@2';

$statsd.increment('test.incr', |(sample_rate => 2));
is $got_message, 'test.incr:1|c|@2';

$statsd.decrement('test.desc');
is $got_message, 'test.desc:-1|c', 'decrement';

$statsd.decrement('test.desc', 2);
is $got_message, 'test.desc:-1|c|@2';

$statsd.decrement('test.desc', |(sample_rate => 2));
is $got_message, 'test.desc:-1|c|@2';

$statsd.count('test.desc', 30);
is $got_message, 'test.desc:30|c', 'count';

$statsd.count('test.desc', 30, 2);
is $got_message, 'test.desc:30|c|@2';

$statsd.count('test.desc', 30, |(sample_rate => 2));
is $got_message, 'test.desc:30|c|@2';

done-testing;