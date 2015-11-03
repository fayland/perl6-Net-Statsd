unit class Net::Statsd;


has Str $.host = '127.0.0.1';
has Int $.port = 8125;
has Str $.namespace is rw = '';

method _socket {
    state $_socket = IO::Socket::INET.new( :$.host, :$.port, :proto{PIO::PROTO_UDP} );
    return $_socket;
}

method count($stat, $count, *%opts) {
    self.send_stats($stat, $count, 'c', %opts);
}

method send_stats($stat is copy, $delta, $type, *%opts) {
    my $sample_rate = %opts<sample_rate>:exists ?? %opts<sample_rate> !! 1;
    if $sample_rate == 1 or 1.rand <= $sample_rate.Int {
        $stat = $stat.subst('::', '', :g);
        $stat = $stat.subst(/[\:|\@]/, '_', :g);
        my $rate = $sample_rate == 1 ?? '' !! '|@' ~ $sample_rate;
        my $tags = %opts<tags>:exists ?? '|#' ~ (%opts<tags>).join(',') !! '';
        my $message = $.namespace ~ $stat ~ ':' ~ $delta ~ '|' ~ $type ~ $rate ~ $tags;
        return self.send_to_socket($message);
    }
}

method send_to_socket($message) {
    return self._socket().print($message);
}

