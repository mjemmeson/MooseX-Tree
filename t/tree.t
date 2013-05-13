# tree.t

use Test::Most;

{

    package MooseX::Tree::Test::Node;

    use Moose;
    with 'MooseX::Tree';

    has name => ( is => 'ro', isa => 'Str', required => 1 );

    1;
}

my $node = 'MooseX::Tree::Test::Node';

ok my $t = $node->new( name => 'root' ), "new";

ok !$t->parent, "no parent";
ok !@{ $t->children }, "no children";

is scalar( $t->ancestors ),   0, "no ancestors";
is scalar( $t->descendants ), 0, "no descendents";

my $child1 = $node->new( name => 'child 1' );
my $child2 = $node->new( name => 'child 2' );
ok $t->add_children( $child1, $child2 ), "add_children";

is $t->children->[0]->name, 'child 1', "got child";

is scalar( $t->ancestors ),   0, "no ancestors";
is scalar( $t->descendants ), 2, "got two descendents";
is_deeply
    [ map { $_->name } $t->descendants ],
    [ 'child 1', 'child 2' ],
    "correct descendants";

my $child3 = $node->new( name => 'child 3' );

$child1->add_children(
    $node->new( name => 'grandchild 1 A' ),
    $node->new( name => 'grandchild 1 B' ),
);

$child3->add_children(
    $node->new( name => 'grandchild 3 A' ),
    $node->new( name => 'grandchild 3 B' ),
);

note "descendants - ordering";

ok my @descendants_pre   = $t->descendants( order => 'pre' ),   "pre order";
ok my @descendants_post  = $t->descendants( order => 'post' ),  "post order";
ok my @descendants_level = $t->descendants( order => 'level' ), "level order";

is scalar(@descendants_pre),   7, "got 7 children and grandchildren";
is scalar(@descendants_post),  7, "got 7 children and grandchildren";
is scalar(@descendants_level), 7, "got 7 children and grandchildren";

#ok @descendants = $t->descendants( hierarchy => 1 ),
#    "got descendants with hierarchy";
#
#is scalar(@descendants), 1, "got one layer";
#is scalar( @{ $descendants[0] } ), 2, "got two descendants in layer";
#is_deeply [ map { $_->name } @{ $descendants[0] } ],
#    [ 'child 1', 'child 2' ],
#    "correct descendants";

done_testing();
