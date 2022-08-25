unit class Person;
# WARNING - AUTO-GENERATED - EDITS WILL BE LOST

has $.last;
has $.first;
has $.middle;
has $.suffix;
has $.nickname;
has $.maiden;
has $.birth;
has $.baptized;
has $.joined;

method new($last, $first, $middle, $suffix, $nickname, $maiden, $birth, $baptized, $joined) {
    self.bless(:$last, :$first, :$middle, :$suffix, :$nickname, :$maiden, :$birth, :$baptized, :$joined);
}

