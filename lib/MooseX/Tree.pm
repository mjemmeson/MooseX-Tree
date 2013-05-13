package MooseX::Tree;

# ABSTRACT: Moose Role to provide simple hierarchical tree functionality to objects

# VERSION

use MooseX::Role::Parameterized;

our $DESCEND_ORDER = 'pre';    # default

parameter parent_link =>       #
    ( is => 'ro', isa => 'Str', default => 'parent' );
parameter parent_type =>       #
    ( is => 'ro', isa => 'Str', default => 'Object' );

parameter children_link =>
    ( is => 'ro', isa => 'Str', default => 'children' );
parameter children_type =>     #
    ( is => 'ro', isa => 'Str', default => 'Object' );

parameter ancestors_method =>
    ( is => 'ro', isa => 'Str', default => 'ancestors' );
parameter descendants_method =>
    ( is => 'ro', isa => 'Str', default => 'descendants' );

role {
    my $parent        = $_[0]->parent_link;
    my $parent_type   = $_[0]->parent_type;
    my $children      = $_[0]->children_link;
    my $children_type = $_[0]->children_type;
    my $ancestors     = $_[0]->ancestors_method;
    my $descendants   = $_[0]->descendants_method;

    my $pre_method   = "${descendants}_pre_order";
    my $post_method  = "${descendants}_post_order";
    my $level_method = "${descendants}_level_order";
    my $group_method = "${descendants}_group_order";

    has $parent => (    #
        is  => 'rw',
        isa => "Maybe[$parent_type]",
    );
    has $children => (
        is      => 'rw',
        isa     => "ArrayRef[$children_type]",
        default => sub { [] },
    );

    method "add_$children" => sub {
        my ( $self, @add ) = @_;

        push @{ $self->$children }, @add;

        return $self;
    };

    method $ancestors => sub {
        my ($self) = @_;

        my @ancestors
            = $self->parent
            ? ( $self->parent, $self->parent->ancestors )
            : ();

        return @ancestors;
    };

    method $descendants => sub {
        my ( $self, %args ) = @_;

        my $order = $args{order} || $DESCEND_ORDER;

        return
              $order eq 'pre'   ? $self->$pre_method
            : $order eq 'post'  ? $self->$post_method
            : $order eq 'level' ? $self->$level_method
            : $order eq 'group' ? $self->$group_method
            :                     die "Unknown descend order: $order";
    };

    method $pre_method => sub {
        return map { $_, $_->$pre_method() } @{ shift->$children };
    };

    method $post_method => sub {
        return map { $_->$post_method(), $_ } @{ shift->$children };
    };

    method $level_method => sub {
        my $self = shift;

        my @list;
        my @queue = @{ $self->$children };

        while ( my $node = shift @queue ) {
            push @list,  $node;
            push @queue, @{ $node->$children };
        }
        return @list;
    };

    method $group_method => sub {
        my $self = shift;

        my @list;
        my @queue = map { [ 0, $_ ] } @{ $self->$children };

        while ( my ( $level, $node ) = @{ shift(@queue) || [] } ) {
            push @{ $list[$level] }, $node;
            push @queue, map { [ $level + 1, $_ ] } @{ $node->$children };
        }
        return @list;
    };
};

1;

