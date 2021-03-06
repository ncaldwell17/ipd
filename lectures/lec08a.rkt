;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname lec08a) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
#|
accumulators
------------

Lets consider a function r2a (relative to absolute) that converts a
series of numbers from their relative positions:

 |------|----|-------|---|---|
 0      50   40      70  30  30


 |------|----|-------|---|---|
 0      50   90      160 190 220

We can represent the positions (both relative and absolute) as lists
of numbers:
|#

;; r2a : [Listof Number] -> [Listof Number]
(check-expect (r2a '()) '())
(check-expect (r2a (list 0 50 40 70 30 30))
              (list 0 50 90 160 190 220))
;; Strategy: structural decomposition
(define (r2a l)
  (cond
    [(empty? l) l]
    [else  (cons (first l)
                 (add-to-each (first l) (r2a (rest l))))]))

;; add-to-each : Number [Listof Number] -> [Listof Number]
(check-expect (add-to-each 1 '()) '())
(check-expect (add-to-each 1 (list 2 3 4)) (list 3 4 5))
(define (add-to-each n l)
  (map (λ (x) (+ x n)) l))

;; Lets look at the hand evaluation:

(r2a (list 1 2 3))
= (cons 1 (add-to-each 1 (r2a (list 2 3))))
= (cons 1 (add-to-each 1 (cons 2 (add-to-each 2 (r2a (list 3))))))
= (cons 1 (add-to-each 1 (cons 2 (add-to-each 2 (cons 3 (add-to-each 3 empty))))))

#|
Now, when you do each of those add-to-each's, the first one will walk
over 0 elements. The second one will walk over 1 element. The third
will walk over 2 elements. What if we had 4 elements in the list? The
extra add-to-each will walk over 3 elements. Something is fishy here.

Indeed, this is just like the reverse function we had in lecture 3 and
it is O(n^2).

What if you were actually doing this work yourself?

You wouldn't have to look at each element in the list n times, would
you? You would just keep track of how far you've been at each step.

Our function isn't doing that. Can we write a variation on that
function that does track this information?

What if we were to make up an additional parameter to the function?
Could that help us? What would that parameter be?
|#

;; r2a-acc : [Listof Number] Number -> [Listof Number]
(define (r2a-acc l sofar)
  (cond
    [(empty? l) empty]
    [else (cons (+ sofar (first l))
                (r2a-acc (rest l) (+ sofar (first l))))]))

;; r2a-2 : [Listof Number] -> [Listof Number]
(define (r2a-2 l) (r2a-acc l 0))

(check-expect (r2a-2 '()) '())
(check-expect (r2a-2 (list 0 50 40 70 30 30))
              (list 0 50 90 160 190 220))


#|
Now, if you analyze the running time of this algorithm, you'll find
that it is linear (ie, it only looks at each element once).
|#


;; ------------------------------------------------------------
;; Lets write a function that converts a binary search tree into a
;; sorted list.


;; a [BT X] is either:
;;  - #false
;;  - (make-node X [BT X] [BT X])
;; with the binary tree invariant
(define-struct node (value left right))

;; in-order [BT X] -> [Listof X]
(check-expect (in-order #f) '())
(check-expect (in-order (make-node 1 #f #f)) (list 1))
(check-expect (in-order
               (make-node 4
                          (make-node 2
                                     (make-node 1 #f #f)
                                     (make-node 3 #f #f))
                          (make-node 6
                                     (make-node 5 #f #f)
                                     (make-node 7 #f #f))))
              (list 1 2 3 4 5 6 7))
(define (in-order bt)
  (cond
    [(node? bt)
     (concat
      (in-order (node-left bt))
      (concat
       (list (node-value bt))
       (in-order (node-right bt))))]
    [else '()]))

;; concat : [Listof X] [Listof X] -> [Listof X]
(check-expect (concat '() '()) '())
(check-expect (concat (list 1 2 3) (list 4 5 6)) (list 1 2 3 4 5 6))
(define (concat l1 l2)
  (cond
    [(empty? l1) l2]
    [else
     (cons (first l1)
           (concat (rest l1) l2))]))

#|
What is the running time of in-order?

Lets say we have a tree that's out of balance, like this:
|#

#;
(make-node
 100
 (make-node
  99
  (make-node
   98
   (make-node 97 ... #false)
   #false)
  #false)
 #false)

;; what are the concat calls going to look like?

#|
  (in-order (make-node 100 ...))
= (concat (in-order (make-node 99 ...)) (concat (list 100) (concat #false)))
= (concat (in-order (make-node 99 ...)) (list 100))
= (concat (concat (in-order (make-node 98 ...)) (concat (list 99) (concat #false)))
          (list 100))
= (concat (concat (in-order (make-node 98 ...)) (list 99)) (list 100))
= (concat (concat (concat (in-order (make-node 97 ...)) (list 98)) (list 99)) (list 100))
= (concat (concat (concat (concat ... (list 97)) (list 98)) (list 99)) (list 100))


So: the innermost concat is going to have a list of length 1 as its
    first argument, the second one is going to have a list of length 2
    as its first argument, the third one a list of length three, etc
    and the outermost one will have a list of length 100 as it first
    argument.

What is the running time of concat? O(n) in the length of its first
argument. So we get the classic sum again and this in-order traversal is
O(n^2)!

How can we fix this? Accumulators.  We add an extra parameter to the
function called the "accumulator" and then we manage that extra
information with a little extra work and then we avoid a ton of work
when we use that extra argument.

In this case, the extra argument is going to be a list of the elements
of the tree that we've already processed. Specifically, one that were
"to the right" in the tree. So imagine a tree like this:

         y
        / \
       /   \
      /     \
     x       z
    / \     / \
   /   \   /   \
  A     B C     D

When we're processing the subtree "D", it will be the empty list. When
we're processing the subtree "C", it will have the element z and all
of the elements in "D" in it. When we're working on A, it will have x,
y, z, and all of the elements in B, C, and D.

Okay, so to design this function, we have to write down a contract for
it that describes the accumulator and its invariant.
|#


;; accumulator invariant: all of the elements of the tree
;; in the sorted order for all of the parts of the tree to the right
;; of the node we're currently processing, in the original tree.
#;
(define (in-order/acc bt sofar)
  (cond
    [(node? bt)

     (node-value bt)

     (in-order/acc
      (node-left bt)
      ?)

     (in-order/acc
      (node-right bt)
      ?)]

    [else ?]))

#|
In each place we have a ? we have to figure out how to either exploit
or maintain the invariant.

Here's the final code. One important piece: in order to maintain the
accumulator invariant for the outer call to in-order/acc and to know
what to do in the base case, the result of the function isn't just the
numbers in the given tree -- it has to be the numbers in the given
tree as well as the numbers in the original tree that are above and
to the right of the given tree.
|#

;; in-order2 : [BT X] -> [Listof X]
(check-expect (in-order2 #false) '())
(check-expect (in-order2 (make-node 1 #false #false)) (list 1))
(check-expect (in-order2
               (make-node 4
                          (make-node 2
                                     (make-node 1 #false #false)
                                     (make-node 3 #false #false))
                          (make-node 6
                                     (make-node 5 #false #false)
                                     (make-node 7 #false #false))))
              (list 1 2 3 4 5 6 7))

(define (in-order2 bt) (in-order/acc bt '()))

;; in-order/acc : [BT X] [Listof X] -> [Listof X]
;; accumulator invariant: all of the elements of the tree
;; in the sorted order for all of the parts of the tree to the right
;; of the node we're currently processing, in the original tree.
(define (in-order/acc bt sofar)
  (cond
    [(node? bt)
     (in-order/acc
      (node-left bt)
      (cons
       (node-value bt)
       (in-order/acc
        (node-right bt)
        sofar)))]
    [else sofar]))

;;;; ------------------------------------------------------------

#|
Okay, now we've seen that we need accumulators and two
examples, but we still need some way to codify *how* to
write accumulators.

1) Identity the need for an accumulator

  - if the function is structurally recursive and the result of
    the function is being processed by another recursive function,
    consider an accumulator.

  - if the function is generative, it's harder. In general,
    you have to notice that you need some additional
    information to be able to compute the answer
    properly. That becomes the accumulator.

2) Set up the accumulator.

  First, figure out what you are accumulating
   - the distance so far (r2a)
   - the nodes where we've been

  and then rewrite the program to take an extra argument,
  and figure out how to maintain the extra argument.

3) Exploit the accumulator

   Next, use the accumulator as part of computing the result
   of the program.

4) re-define the original function in terms of the
   accumulator.

As you do the process, you must figure out the _accumulator
invariant_. 

This is a mathematical statement that relates the initial
argument to the function and the accumulator to the current
value.

  For example:
   - r2a: the distance back to the first point processed
   - in-order: the sorted elements to the right
     and above in the original tree
|#


;; ------------------------------------------------------------
;; practicing accumulators

#|
Reverse's running time can be improved to linear using
accumulators. Here's how:

;; reverse : [Listof X] -> [listof X]
(define (rev l)
  (cond
    [(empty? l) empty]
    [else (add-at-end (first l)
                      (rev (rest l)))]))

1. what should the accumulator be?

   the reverse of the list elements
   we've seen so far

2. rewrite to propogate the accumulator:

;; rev-a : (listof X) (listof X) -> (listof X)
(define (rev-a l acc)
  (cond
    [(empty? l) ...]
    [else  (rev-a (rest l) (cons (first l) acc)) ...]))

3. take advantage:

;; reverse : (listof X) (listof X) -> (listof X)
(define (rev-a l acc)
  (cond
    [(empty? l) acc]
    [else (rev-a (rest l) (cons (first l) acc))]))

4. rewrite original

(define (rev l) (rev-a l empty))

hand evaluation:

  (rev (list 1 2 3))
= (rev-a (list 1 2 3) empty)
= (rev-a (list 2 3) (list 1))
= (rev-a (list 3) (list 2 1))
= (rev-a (list) (list 3 2 1))
= (list 3 2 1)

voila.
|#


#|
In the binomial heap, the "add" operation's carry is a ripe spot for
an accumulator. Fix the code so that it adds an accumulator whose
value is the "carry in", i.e., it will be a tree that was produced
from the preceding digit, if there was one, or #false if there wasn't
one. See lec08-binomial-heap-acc.rkt for the solution.
|#
