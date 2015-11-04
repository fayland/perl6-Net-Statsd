unit class Net::Statsd;


has Str $.host = '127.0.0.1';
has Int $.port = 8125;
has Str $.namespace is rw = '';

method _socket {
    state $_socket = IO::Socket::INET.new( :host($!host), :port($!port), :proto(17) );
    return $_socket;
}

multi method increment($stat, Int $sample_rate) {
    self.count($stat, 1, |(sample_rate => $sample_rate));
}

multi method increment($stat, *%opts) {
    self.count($stat, 1, |%opts);
}

multi method decrement($stat, Int $sample_rate) {
    self.count($stat, -1, |(sample_rate => $sample_rate));
}

multi method decrement($stat, *%opts) {
    self.count($stat, -1, |%opts);
}

multi method count($stat, $count, Int $sample_rate) {
    self.send_stats($stat, $count, 'c', |(sample_rate => $sample_rate));
}

multi method count($stat, $count, *%opts) {
    self.send_stats($stat, $count, 'c', |%opts);
}

multi method gauge($stat, $value, Int $sample_rate) {
    self.send_stats($stat, $value, 'g', |(sample_rate => $sample_rate));
}

multi method gauge($stat, $value, *%opts) {
    self.send_stats($stat, $value, 'g', |%opts);
}

multi method histogram($stat, $value, Int $sample_rate) {
    self.send_stats($stat, $value, 'h', |(sample_rate => $sample_rate));
}

multi method histogram($stat, $value, *%opts) {
    self.send_stats($stat, $value, 'h', |%opts);
}

multi method timing($stat, Int $value, Int $sample_rate) {
    self.send_stats($stat, $value, 'ms', |(sample_rate => $sample_rate));
}

multi method timing($stat, Int $value, *%opts) {
    self.send_stats($stat, $value, 'ms', |%opts);
}

multi method set($stat, $value, Int $sample_rate) {
    self.send_stats($stat, $value, 's', |(sample_rate => $sample_rate));
}

multi method set($stat, $value, *%opts) {
    self.send_stats($stat, $value, 's', |%opts);
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

