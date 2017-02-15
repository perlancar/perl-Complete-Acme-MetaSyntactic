package Complete::Acme::MetaSyntactic;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Complete::Common qw(:all);
use List::MoreUtils qw(uniq);

our %SPEC;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       complete_meta_categories
                       complete_meta_themes
                       complete_meta_themes_and_categories
               );

#TODO: complete_meta_names

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Completion routines for Acme::MetaSyntactic',
};

$SPEC{complete_meta_themes} = {
    v => 1.1,
    summary => 'Complete from list of available themes',
    args => {
        %arg_word,
    },
    result_naked => 1,
};
sub complete_meta_themes {
    require Complete::Util;
    require PERLANCAR::Module::List;

    my %args = @_;

    my $res = PERLANCAR::Module::List::list_modules(
        "Acme::MetaSyntactic::", {list_modules=>1});
    my @ary = sort keys %$res;
    for (@ary) {
        s/\AAcme::MetaSyntactic:://;
    }
    @ary = grep { !/^[A-Z]/ } @ary;
    Complete::Util::complete_array_elem(
        word => $args{word},
        array => \@ary,
    );
}

$SPEC{complete_meta_categories} = {
    v => 1.1,
    summary => 'Complete from list of categories for a particular theme',
    args => {
        %arg_word,
        theme => {
            schema => ['str*', match => qr/\A\w+\z/],
            req => 1,
            completion => sub {
                complete_meta_themes(@_);
            },
        },
    },
    result_naked => 1,
};
sub complete_meta_categories {
    no strict 'refs';
    require Complete::Util;

    my %args = @_;

    my $theme = $args{theme} or return [];
    my $pkg = "Acme::MetaSyntactic::$theme";
    (my $pkg_pm = "$pkg.pm") =~ s!::!/!g;
    eval { require $pkg_pm; 1 } or return [];
    my $meta = $pkg->new;
    Complete::Util::complete_array_elem(
        word => $args{word},
        array => [$pkg->categories],
    );
}

$SPEC{complete_meta_themes_and_categories} = {
    v => 1.1,
    summary => 'Complete from list of available themes (or "theme/category")',
    description => <<'_',

This routine can complete from a list of themes, like `complete_meta_themes()`.
Additionally, if the word is in the form of "word/" or "word/rest" then the
"rest" will be completed from list of categories of theme "word".

_
    args => {
        %arg_word,
    },
    result_naked => 1,
};
sub complete_meta_themes_and_categories {
    require Complete::Util;
    require PERLANCAR::Module::List;

    my %args = @_;
    my $word = $args{word};

    if ($word =~ /\A(\w*)\z/) {
        return complete_meta_themes(word => $word);
    } elsif ($word =~ m!\A(\w+)/((?:/\w+)*\w*)\z!) {
        my ($theme, $cat) = ($1, $2);
        my $themes = complete_meta_themes(word => $theme);
        return [] unless @$themes == 1;
        my $pkg = "Acme::MetaSyntactic::$themes->[0]";
        (my $pkg_pm = "$pkg.pm") =~ s!::!/!g;
        return [] unless eval { require $pkg_pm; 1 };
        my $meta = $pkg->new;
        my $cats = Complete::Util::complete_array_elem(
            word => $cat,
            array => [$meta->categories],
        );
        return [map {"$themes->[0]/$_"} @$cats];
    } else {
        return [];
    }
}

1;
#ABSTRACT:
