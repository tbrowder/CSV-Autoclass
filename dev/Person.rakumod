unit class Person;
# WARNING - AUTO-GENERATED - EDITS WILL BE LOST

has $.index;
has $.email;
has $.last;
has $.first;
has $.middle;
has $.suffix;
has $.nickname;
has $.maiden;
has $.sex;
has $.member;
has $.;

method new($index, $email, $last, $first, $middle, $suffix, $nickname, $maiden, $sex, $member, $) {
    self.bless(:$index, :$email, :$last, :$first, :$middle, :$suffix, :$nickname, :$maiden, :$sex, :$member, :$);
}

