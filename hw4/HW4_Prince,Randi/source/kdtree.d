import std.stdio;
import std.math;
import std.algorithm;
import std.range;

import common;

struct KDTree(size_t Dim) {
    alias PD = Point!Dim;
    // alias P2 = Point!2;
    // An x-split node and a y-split node are different types
    Node!0 root;

    this(PD[] points) {
        root = new Node!0(points);
    }
    class Node ( size_t splitDimension ) {
        // If this is an x node, the next level is "y"
        // If this is a y node, the next level is "z", etc
        enum thisLevel = splitDimension; // This lets you refer to a node's split level with theNode.thisLevel
        enum nextLevel = (splitDimension + 1) % Dim;
        Node!nextLevel left, right; // Child nodes split by the next level
        PD splitPoint;
        // PD[] points;

        this(PD[] pts) {

            PD[] leftPoints = pts.medianByDimension!thisLevel; // partition based on current dimmension: 0 is x, 1 is y, 2 is z
            writeln(leftPoints);
            PD[] rightPoints = pts[leftPoints.length + 1 .. $];

            splitPoint = pts[leftPoints.length];
            if (leftPoints.length > 0) {
                left = new Node!nextLevel(leftPoints);
            }
            if (rightPoints.length > 0) {
                right = new Node!nextLevel(rightPoints);
            }     
            
        }

    }

   
    PD[] rangeQuery( PD queryPt, float r ){
        PD[] ret;
        void recurse(NodeType)( NodeType n ){
            //first check if split point is close to query pt
            // if so, add to list 
            if (distance(n.splitPoint, queryPt) < r) {
                ret ~= n.splitPoint;
            }

            // now to to check if we should recurse left
            // if the query pt less the radius is less than the split pt we know to go left b/c split pt is the median
            if (n.left && (queryPt[n.thisLevel] - r < n.splitPoint[n.thisLevel])) {
                recurse( n.left ); // This will work.
            }

            // now to to check if we should recurse right
            // if the query pt plus the radius is more than the split pt we know to go right b/c split pt is the median 
            if (n.right && (queryPt[n.thisLevel] + r > n.splitPoint[n.thisLevel])) {
                recurse( n.right ); // This will work.
            }
            
        }
        recurse( root );
        return ret;
    }

    PD[] knnQuery(PD queryPt, int k) {
        auto priorityQueue = makePriorityQueue(queryPt);

        void recurse(size_t Dimension, size_t Dim)(Node!Dimension n, AABB!Dim aabb) {
            if (priorityQueue.length < k) { // if length is less than k, add to list
                priorityQueue.insert(n.splitPoint);
            } else if (distance(n.splitPoint, queryPt) < distance(queryPt, priorityQueue.front)) { // if split to query is less than query to worst point
                priorityQueue.popFront; // remove worst from list
                priorityQueue.insert(n.splitPoint); // and add point
            }

            // now to take care of the bounding box, well need a right and left
            AABB!Dim leftAABB, rightAABB;

            leftAABB.min = aabb.min.dup;
            leftAABB.max = aabb.max.dup;
            rightAABB.min = aabb.min.dup;
            rightAABB.max = aabb.max.dup;

            leftAABB.max[n.thisLevel] = n.splitPoint[n.thisLevel]; //left max = the root at this level
            rightAABB.min[n.thisLevel] = n.splitPoint[n.thisLevel]; // right min = root at this level

            // if length is less than k or dis between query and closest in the box is less than the dist of query to worst pt we go left 
            if (n.left && ((priorityQueue.length < k) || distance(closest(leftAABB, queryPt), queryPt) < distance(queryPt, priorityQueue.front))) {
                recurse(n.left, leftAABB);
            }

            // do the same on the right
            if (n.right && ((priorityQueue.length < k) || distance(closest(rightAABB, queryPt), queryPt) < distance(queryPt, priorityQueue.front))) {
                recurse(n.right, rightAABB);
            }

        }
        // now the root aabb
        AABB!Dim rootAABB;
        rootAABB.min[] = -float.infinity;
        rootAABB.max[] = float.infinity;
        recurse(root, rootAABB);

        return priorityQueue.release;
    }
}

unittest {
    auto kdtree = KDTree!2([Point!2([.5, .5]), Point!2([1, 1]),
    Point!2([0.75, 0.4]), Point!2([0.4, 0.74])]);

    writeln(kdtree);

    writeln("kdtree range query!");
    foreach(p; kdtree.rangeQuery(Point!2([1,1]), .7)) {
        writeln(p);
    }
    writeln(kdtree.rangeQuery(Point!2([1,1]), .7).length);
    assert(kdtree.rangeQuery(Point!2([1,1]), .7).length == 3);

    writeln("kdtree knn query!");
    foreach(p; kdtree.knnQuery(Point!2([1,1]), 3)) {
        writeln(p);
    }
    
}