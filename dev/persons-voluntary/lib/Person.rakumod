unit class Person;

has $.index is rw = '';
has $.email is rw = '';
has $.last is rw = '';
has $.first is rw = '';
has $.middle is rw = '';
has $.suffix is rw = '';
has $.nickname is rw = '';
has $.maiden is rw = '';
has $.sex is rw = '';
has $.member is rw = '';
has $.phone is rw = '';

# Special multi methods allow setting attribute values
# programmatically via a special single method
multi method index($v)    { $!index = $v; }
multi method email($v)    { $!email = $v; }
multi method last($v)     { $!last = $v; }
multi method first($v)    { $!first = $v; }
multi method middle($v)   { $!middle = $v; }
multi method suffix($v)   { $!suffix = $v; }
multi method nickname($v) { $!nickname = $v; }
multi method maiden($v)   { $!maiden = $v; }
multi method sex($v)      { $!sex = $v; }
multi method member($v)   { $!member = $v; }
multi method phone($v)    { $!phone = $v; }

multi method index()    { $!index }
multi method email()    { $!email }
multi method last()     { $!last }
multi method first()    {
    # Problem: not all clients listened to the instructions,
    # so some used 'first', some used only 'nickname', and
    # some used both.
    $!first ~~ /\S/ ?? $!first !! $!nickname
}
multi method middle()   { $!middle }
multi method suffix()   { $!suffix }
multi method nickname() {
    # Problem: not all clients listened to the instructions,
    # so some used 'first', some used only 'nickname', and
    # some used both.
    $!nickname ~~ /\S/ ?? $!nickname !! $!first
}
multi method maiden()   { $!maiden }
multi method sex()      { $!sex }
multi method member()   { $!member }
multi method phone()    { $!phone }

method new($index, $email, $last, $first, $middle, $suffix, $nickname, $maiden, $sex, $member, $phone) {
    self.bless(:$index, :$email, :$last, :$first, :$middle, :$suffix, :$nickname, :$maiden, :$sex, :$member, :$phone);
}

method set-value(:$field!, :$value!) {
    self."$field"($value);
}

method list-fields(--> List) {
    # THIS WORKS
    #| Return a list of the the attributes (fields) of the class instance
    my @attrs = self.^attributes;
    my @nams;
    for @attrs -> $a {
        # need to get its name
        my $v = $a.name;
        # the name is prefixed by its sigil and twigil
        # which we don't want
        $v ~~ s/\S\S//;
        @nams.push: $v;
    }
    @nams
}

method list-values(--> List) {
    # THIS WORKS
    #| Return a list of the values for the attributes of the class instance
    my @attrs = self.^attributes;
    my @vals;
    for @attrs -> $a {
        # need to get its value
        my $v = $a.get_value: self;
        @vals.push: $v;
    }
    @vals
}

method firstname {
    self.first ?? self.first !! self.nickname
}
