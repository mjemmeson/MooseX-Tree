package MooseX::Tree;

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
};

1;

__END__

sub traverse {
    my $self = shift;
    my $order = shift;
    $order = $self->PRE_ORDER unless $order;
 
    if ( wantarray ) {
        my @list;
 
        if ( $order eq $self->PRE_ORDER ) {
            @list = ($self);
            push @list, map { $_->traverse( $order ) } @{$self->{_children}};
        }
        elsif ( $order eq $self->POST_ORDER ) {
            @list = map { $_->traverse( $order ) } @{$self->{_children}};
            push @list, $self;
        }
        elsif ( $order eq $self->LEVEL_ORDER ) {
            my @queue = ($self);
            while ( my $node = shift @queue ) {
                push @list, $node;
                push @queue, @{$node->{_children}};
            }
        }
        else {
            return $self->error( "traverse(): '$order' is an illegal traversal order" );
        }
 
        return @list;
    }
    else {
        my $closure;
 
        if ( $order eq $self->PRE_ORDER ) {
            my $next_node = $self;
            my @stack = ( $self );
            my @next_idx = ( 0 );
 
            $closure = sub {
                my $node = $next_node;
                return unless $node;
                $next_node = undef;
 
                while ( @stack && !$next_node ) {
                    while ( @stack && !exists $stack[0]->{_children}[ $next_idx[0] ] ) {
                        shift @stack;
                        shift @next_idx;
                    }
 
                    if ( @stack ) {
                        $next_node = $stack[0]->{_children}[ $next_idx[0]++ ];
                        unshift @stack, $next_node;
                        unshift @next_idx, 0;
                    }
                }
 
                return $node;
            };
        }
        elsif ( $order eq $self->POST_ORDER ) {
            my @stack = ( $self );
            my @next_idx = ( 0 );
            while ( @{ $stack[0]->{_children} } ) {
                unshift @stack, $stack[0]->{_children}[0];
                unshift @next_idx, 0;
            }
 
            $closure = sub {
                my $node = $stack[0];
                return unless $node;
 
                shift @stack; shift @next_idx;
                $next_idx[0]++;
 
                while ( @stack && exists $stack[0]->{_children}[ $next_idx[0] ] ) {
                    unshift @stack, $stack[0]->{_children}[ $next_idx[0] ];
                    unshift @next_idx, 0;
                }
 
                return $node;
            };
        }
        elsif ( $order eq $self->LEVEL_ORDER ) {
            my @nodes = ($self);
            $closure = sub {
                my $node = shift @nodes;
                return unless $node;
                push @nodes, @{$node->{_children}};
                return $node;
            };
        }
        else {
            return $self->error( "traverse(): '$order' is an illegal traversal order" );
        }
 
        return $closure;
    }
}

