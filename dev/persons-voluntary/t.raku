class Person {}
my $p = Person.new;
my $b = "image.jpg";

my $pstr  = "";
my $alpha = "";
my %aindex = []; # for future use as top index selector: A B ... Z
    my $name = "foo, bar";
    my $initial = $name.comb.head.uc;
    note "DEBUG: initial = $initial";
    if $initial ne $alpha {
        $alpha = $initial;
        #%aindex{$alpha}<obj>   = $p;
        #%aindex{$alpha}<name>  = $name;
    }
    my $s = qq:to/HERE/;
        \<div>
            \<img src='images/$b'>
            \<div>$name\</div>
        \</div>
    HERE
    $pstr ~= $s;

