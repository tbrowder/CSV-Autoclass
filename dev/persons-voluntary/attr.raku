method list-fields(--> List) {
    #| Return a list of the the attributes (fields) of the class instance
    my @attrs = self.^attributes;
    my @names;
    for @attrs -> $a {
        my $v = $a.name;
        # The name is prefixed by its sigil and twigil
        # which we don't want
        $v ~~ s/\S\S//;
        @names.push: $v;
    }
    @names
}

method list-values(--> List) {
    #| Return a list of the values for the attributes 
    #| of the class instance
    my @attrs = self.^attributes;
    my @values;
    for @attrs -> $a {
        # Syntax is not obvious
        my $v = $a.get_value: self;
        @values.push: $v;
    }
    @values
}

