use Test;

plan 5;

is %*ENV<CSV_AUTOCLASS_SEPCHAR>:exists, False;
{
    # TODO fix so tests don't affect external %*ENV
    is %*ENV<CSV_AUTOCLASS_SEPCHAR>:exists, False;

    %*ENV<CSV_AUTOCLASS_SEPCHAR> = "comma";
    is %*ENV<CSV_AUTOCLASS_SEPCHAR>:exists, True;
    is %*ENV<CSV_AUTOCLASS_SEPCHAR>, "comma";

    %*ENV<CSV_AUTOCLASS_SEPCHAR>:delete;
}
is %*ENV<CSV_AUTOCLASS_SEPCHAR>:exists, False;
