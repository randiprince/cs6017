import std.stdio;
import std.math;
import std.algorithm;
import std.range;

import common;

struct QuadTree(size_t Dim) {
    alias P2 = Point!2;

    Node root;

    this(P2[] points) {
        auto aabb = boundingBox(points);
        root = new Node(points, aabb);
    }

    class Node {
        bool isLeaf;
        P2[] points;
        AABB!2 aabb;
        Node[4] childNodes;
        // P2 midpoint;

        this(P2[] points, AABB!2 aabb) { 
            // need to check if leaf
            // leaf if number of points less than X
            if (points.length < 2) {
                isLeaf = true;
                this.points = points.dup;
                this.aabb = aabb;
            } else {
                // isLeaf = false;
                // make 4 children of internal node
                // need midpoint first
                P2 midpoint = (aabb.max + aabb.min) / 2;

                //partition into left and right haf
                auto rightHalf = points.partitionByDimension!0(midpoint[0]);
                auto leftHalf = points[0 .. $ - rightHalf.length];

                // now we need to get the four children: 
                
                //right half top
                auto rightHalfTop = rightHalf.partitionByDimension!1(midpoint[1]);
                // right half bottom
                auto rightHalfBottom = rightHalf[0 .. $ - rightHalfTop.length]; 
                // left half top
                auto leftHalfTop = leftHalf.partitionByDimension!1(midpoint[1]);
                //left half bottom
                auto leftHalfBottom = leftHalf[0 .. $ - leftHalfTop.length];

                AABB!2 rightHalfTopBB, leftHalfTopBB, rightHalfBottomBB, leftHalfBottomBB;
                // NE corner
                rightHalfTopBB.min = midpoint.dup;
                rightHalfTopBB.max = aabb.max.dup;
                
                // NW corner
                leftHalfTopBB.min = P2([aabb.min[0], midpoint[1]]);
                leftHalfTopBB.max = P2([midpoint[0], aabb.max[1]]);

                // SE corner 
                rightHalfBottomBB.min = P2([midpoint[0], aabb.min[1]]);
                rightHalfBottomBB.max = P2([aabb.max[0], midpoint[1]]);

                //SW corner 
                leftHalfBottomBB.min = P2([aabb.min[0], aabb.min[1]]);
                leftHalfBottomBB.max = midpoint.dup;

                // create the child nodes:
                childNodes[0] = new Node(leftHalfTop, leftHalfTopBB);
                childNodes[1] = new Node(rightHalfTop, rightHalfTopBB);
                childNodes[2] = new Node(leftHalfBottom, leftHalfBottomBB);
                childNodes[3] = new Node(rightHalfBottom, rightHalfBottomBB);
            }
        }
    }

    P2[] rangeQuery( P2 queryPt, float r ){
        P2[] ret;
        void recurse(Node n){
            if (n.isLeaf) {
                foreach(const ref point; n.points) {
                    if (distance(point, queryPt) < r) {
                        ret ~= point;
                    }
                }
            } else  { //internal node
                // need to check to see which node the point is in
                foreach(child; n.childNodes){
                    if (distance(closest(child.aabb, queryPt), queryPt) < r) { // if in that child node recurse!!!!
                        recurse(child);
                    }
                }
            }
        }
        recurse( root );
        return ret;
    }
    
    P2[] knnQuery(P2 queryPt, int k) {
        auto priorityQueue = makePriorityQueue(queryPt);

        void recurse(Node n) {
            if (n.isLeaf) {
                foreach(point; n.points){
                    
                    if (priorityQueue.length < k) {
                        priorityQueue.insert(point);
                    } else if (distance(point, queryPt) < distance(queryPt, priorityQueue.front)) {
                        priorityQueue.popFront;
                        priorityQueue.insert(point);
                    }
                }
            } else  { //internal node
                foreach(child; n.childNodes) {
                    if (priorityQueue.length < k || distance(closest(child.aabb, queryPt), queryPt) < distance(queryPt, priorityQueue.front)) {
                        recurse(child);
                    }
                }
            }
        }
        recurse(root);
        return priorityQueue.release;
    }
    
}

unittest{
    auto onePt = [Point!2([.5, .5])];
    auto singlePtQuadTree = QuadTree!2(onePt);

    writeln("test: quadtree constructor!");
    assert(singlePtQuadTree.root.isLeaf == true);

    auto points = [Point!2([.5, .5]), Point!2([1, 1]),
                   Point!2([0.75, 0.4]), Point!2([0.4, 0.74])];

    auto qt = QuadTree!2(points);
    
    writeln(qt);
    writeln("quadtree range query");
    foreach(p; qt.rangeQuery(Point!2([1,1]), .7)){
        writeln("write p");
        writeln(p);
    }
    writeln(qt.rangeQuery(Point!2([1,1]), .7).length);
    assert(qt.rangeQuery(Point!2([1,1]), .7).length == 3);
    writeln("quadtree knn");
    foreach(p; qt.knnQuery(Point!2([1,1]), 3)){
        writeln(p);
    }
}
