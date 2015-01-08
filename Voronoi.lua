--[[

Copyright © 2010 David Ng

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

Based of the work of Steve J. Fortune (1987) A Sweepline Algorithm for Voronoi Diagrams,
Algorithmica 2, 153-174, and its translation to C++ by Matt Brubeck, 
http://www.cs.hmc.edu/~mbrubeck/voronoi.html
--]]
math.randomseed(os.time())

Heap = {}
function Heap:new() 
    o = {heap = {}, nodes = {}} 
    setmetatable(o, self) 
    self.__index = self 
    return o
end

function Heap:push(k, v)
    assert(v ~= nil, "cannot push nil")
    local t = self.nodes
    local h = self.heap
    local n = #h + 1 -- node position in heap array (leaf)
    local p = (n - n % 2) / 2 -- parent position in heap array
    h[n] = k -- insert at a leaf
    t[k] = v
    while n > 1 and t[h[p]] > v do -- climb heap?
        h[p], h[n] = h[n], h[p]
        n = p
        p = (n - n % 2) / 2
    end
end

function Heap:pop()
    local t = self.nodes
    local h = self.heap
    local s = #h
    assert(s > 0, "cannot pop from empty heap")
    local e = h[1] -- min (heap root)
    local r = t[e]
    local v = t[h[s]]
    h[1] = h[s] -- move leaf to root
    h[s] = nil -- remove leaf
    t[e] = nil
    s = s - 1
    local n = 1 -- node position in heap array
    local p = 2 * n -- left sibling position
    if s > p and t[h[p]] > t[h[p + 1]] then
        p = 2 * n + 1 -- right sibling position
    end
    while s >= p and t[h[p]] < v do -- descend heap?
        h[p], h[n] = h[n], h[p]
        n = p
        p = 2 * n
    if s > p and t[h[p]] > t[h[p + 1]] then
        p = 2 * n + 1
    end
end
    return e, r
end

function Heap:isEmpty() 
    return self.heap[1] == nil 
end

DoubleLinkedList = {}
function DoubleLinkedList:new()
    o = {first = nil, last = nil} -- empty list head
    setmetatable(o, self) 
    self.__index = self 
    return o
end

function DoubleLinkedList:insertAfter(node, data)
    local new = {prev = node, next = node.next, x = data.x, y = data.y } -- creates a new node
    node.next = new -- the node after node is the new node
    if node == self.last then -- check if the old node is the last node...
        self.last = new -- ...and set the new node as last node
    else
        --otherwise set the next nodes previous node to the new one
        new.next.prev = new 
    end
    return new -- return the new node
end

function DoubleLinkedList:insertAtStart(data)
    local new = {prev = nil, next = self.first, x = data.x, y = data.y} -- create the new node
    if not self.first then -- check if the list is empty
        self.first = new -- the new node is the first and the last in this case
        self.last = new
   else
        -- the node before the old first node is the new first node
        self.first.prev = new
        self.first = new -- update the list's first field
   end
   return new
end

function DoubleLinkedList:delete(node)
    if node == self.first then -- check if the node is the first one...
        -- ...and set the new first node if we remove the first
        self.first = node.next
    else
        -- set the previous node's next node to the next node
        node.prev.next = node.next
    end
    
    if node == self.last then -- check if the node is the last one...
        -- ...the new last node is the node before the deleted node
        self.last = node.prev
    else
        node.next.prev = node.prev -- update the next node's prev field
    end
end

function DoubleLinkedList:nextNode(node)
    return (not node and self.first) or node.next
end

function processEvent(event)
    if event.valid then
        segment = {startPoint = {x = event.x, y = event.y}, endPoint = {x = 0, y = 0}, done = false, type = 1}
        table.insert(segments, segment)
        --Remove the associated arc from the front, and update segment info
        
        beachline:delete(event.arc)
        
        if event.arc.prev then
            event.arc.prev.seg1 = segment
        end
        
        if event.arc.next then
            event.arc.next.seg0 = segment
        end
        
        --Finish the edges before and after arc.
        if event.arc.seg0 then
            event.arc.seg0.endPoint = {x = event.x, y = event.y}
            event.arc.seg0.done = true
        end    
            
        if event.arc.seg1 then
            event.arc.seg1.endPoint = {x = event.x, y = event.y}
            event.arc.seg1.done = true
        end    
        
        -- debugging vertix list!!!
        table.insert(vertex, {x = event.x, y = event.y})
        
        --Recheck circle events on either side of p:
        if (event.arc.prev) then
            check_circle_event(event.arc.prev, event.x)
        end
        if (event.arc.next) then
            check_circle_event(event.arc.next, event.x)
        end    
        event.arc = nil
   end
   event = nil 
end
function processPoint(point)
    --Adds a point to the beachline
    local intersect = intersect
    if (not beachline.first) then
        beachline:insertAtStart(point)
        return
    end
    
    --Find the current arc(s) at height p.y (if there are any).
    for arc in beachline.nextNode, beachline do
        z = (intersect(point,arc))
        if z then
            --New parabola intersects arc i.  If necessary, duplicate i.
            -- ie if there is a next node, but there is not interation, then creat a duplicate
            if not (arc.next and (intersect(point,arc.next))) then
                beachline:insertAfter(arc, arc)
            else    
                --print("test", arc.next,intersect(point,arc.next).x,intersect(point,arc.next).y, z.x,z.y  )
                return
            end    
            arc.next.seg1 = arc.seg1
            
            --Add p between i and i->next.
            beachline:insertAfter(arc, point)

            
            segment = {startPoint = {x = z.x, y = z.y}, endPoint = {x = 0, y = 0}, done = false, type = 2}
            segment2 = {startPoint = {x = z.x, y = z.y}, endPoint = {x = 0, y = 0}, done = false, type = 2}

            -- debugging segment list!!!
            table.insert(segments, segment)
            table.insert(segments, segment2)

            
            --Add new half-edges connected to i's endpoints.
            arc.next.seg0 = segment
            arc.seg1 = segment
            arc.next.seg1 = segment2
            arc.next.next.seg0 = segment2
            
            --Check for new circle events around the new arc:
            check_circle_event(arc, point.x)
            check_circle_event(arc.next, point.x)
            check_circle_event(arc.next.next, point.x)

            return
            
        end    
    end
    --Special case: If p never intersects an arc, append it to the list.
    -- Find the last node.
    
    beachline:insertAtStart(point)

    segment = {startPoint = {x = X0, y = (beachline.last.y + beachline.last.prev.y) / 2}, endPoint = {x = 0, y = 0}, done = false, type = 3}
    
    table.insert(segments, segment)
    
    beachline.last.seg0 = segment
    beachline.last.prev.seg1 = segment
end

function check_circle_event(arc, x0)
    --Look for a new circle event for arc i.
    --Invalidate any old event.

    if (arc.event and arc.event.x ~= x0) then
        arc.event.valid = false
    end
    arc.event = nil

    if ( not arc.prev or not arc.next) then
        return
    end
    
    local a = arc.prev
    local b = arc
    local c = arc.next

    if ((b.x-a.x)*(c.y-a.y) - (c.x-a.x)*(b.y-a.y) >= 0) then
        return false
    end    

    --Algorithm from O'Rourke 2ed p. 189.
    local A = b.x - a.x
    local B = b.y - a.y
    local C = c.x - a.x
    local D = c.y - a.y
    local E = A*(a.x+b.x) + B*(a.y+b.y)
    local F = C*(a.x+c.x) + D*(a.y+c.y)
    local G = 2*(A*(c.y-b.y) - B*(c.x-b.x))

    if (G == 0) then
        --return false --Points are co-linear
        print("g is 0")
    end

    --Point o is the center of the circle.
    local o = {}
    o.x = (D*E-B*F)/G
    o.y = (A*F-C*E)/G

    --o.x plus radius equals max x coordinate.
    local x = o.x + math.sqrt( math.pow(a.x - o.x, 2) + math.pow(a.y - o.y, 2) )
    
    if x and x > x0 then
        --Create new event.
        arc.event = {x = o.x, y = o.y, arc = arc, valid = true, event = true}
        events:push(arc.event, x)
    end
end

function intersect(point, arc)
    --Will a new parabola at point p intersect with arc i?
    local res = {}
    if (arc.x == point.x) then 
        return false 
    end

    if (arc.prev) then
        --Get the intersection of i->prev, i.
        a = intersection(arc.prev, arc, point.x).y
    end    
    if (arc.next) then
        --Get the intersection of i->next, i.
        b = intersection(arc, arc.next, point.x).y
    end    
    --print("intersect", a,b,p.y)
    if (( not arc.prev or a <= point.y) and (not arc.next or point.y <= b)) then
        res.y = point.y
        -- Plug it back into the parabola equation.
        res.x = (arc.x*arc.x + (arc.y-res.y)*(arc.y-res.y) - point.x*point.x) / (2*arc.x - 2*point.x)
        return res
    end
    return false
end
function intersection(p0, p1, l)
    -- Where do two parabolas intersect?
    
    local res = {}
    local p = {x = p0.x, y = p0.y}

    if (p0.x == p1.x) then
        res.y = (p0.y + p1.y) / 2
    elseif (p1.x == l) then
        res.y = p1.y
    elseif (p0.x == l) then
        res.y = p0.y
        p = p1
   else
      -- Use the quadratic formula.
      local z0 = 2*(p0.x - l);
      local z1 = 2*(p1.x - l);

      local a = 1/z0 - 1/z1;
      local b = -2*(p0.y/z0 - p1.y/z1);
      local c = (p0.y*p0.y + p0.x*p0.x - l*l)/z0 - (p1.y*p1.y + p1.x*p1.x - l*l)/z1
      res.y = ( -b - math.sqrt(b*b - 4*a*c) ) / (2*a)
   end
   
   -- Plug back into one of the parabola equations.
   res.x = (p.x*p.x + (p.y-res.y)*(p.y-res.y) - l*l)/(2*p.x-2*l)
   return res
end

function finishEdges()
    --Advance the sweep line so no parabolas can cross the bounding box.
    l = X1 + (X1-X0) + (Y1-Y0)

    --Extend each remaining segment to the new parabola intersections.
    for arc in beachline.nextNode, beachline do
        if arc.seg1 then
            p = intersection(arc, arc.next, l*2)
            arc.seg1.endPoint = {x = p.x, y = p.y}
            arc.seg1.done = true
        end    
    end
end

points_list = {}
graphics = {}

X0 = 50
X1 = 700
Y0 = 50
Y1 = 970
NUMPOINT = 100

--Point that share the exact same coordinates can cause problems; adding a random decimal is a quick fix.
for i = 1,NUMPOINT do
    points_list[i] = {x = math.random(X0,X1) + math.random(),y = math.random(Y0,Y1) + math.random(),dx = math.random(-2,2), dy = math.random(-2,2)}
end

voronoi = {}
function voronoi:enterFrame( event )

    --Clear and reset tables
    for i = #graphics,1,-1 do
        graphics[i]:removeSelf()
        graphics[i] = nil
    end
    graphics = {}
    beachline = DoubleLinkedList:new()
    events = Heap:new()
    vertex = {}
    segments = {}
    
    --Update point positions
    for i = 1,#points_list do
        points_list[i].x =  points_list[i].x + points_list[i].dx
        if points_list[i].x < X0 then
            points_list[i].x = X0
            points_list[i].dx = -1*points_list[i].dx
        end
        if points_list[i].x > X1 then
            points_list[i].x = X1
            points_list[i].dx = -1*points_list[i].dx
        end
        
        points_list[i].y =  points_list[i].y + points_list[i].dy
        if points_list[i].y < Y0 then
            points_list[i].y = Y0
            points_list[i].dy = -1*points_list[i].dy
        end
        if points_list[i].y > Y1 then
            points_list[i].y = Y1
            points_list[i].dy = -1*points_list[i].dy
        end
        
        local x = display.newCircle(points_list[i].x,points_list[i].y, 5)
        x:setFillColor(0,255,0,255)  
        table.insert(graphics,x)
        events:push(points_list[i], points_list[i].x)
    end

    
    while not events:isEmpty() do
        e, x = events:pop()
        if e.event then
            processEvent(e)
        else
            processPoint(e)
        end    
    end
    finishEdges()
    
    
    --Draw the vertex and line segments
    for i = 1, #vertex do
        local x = display.newCircle(vertex[i].x,vertex[i].y, 5)
        x:setFillColor(0,0,255,255)  
        table.insert(graphics,x) 
    end
    for i = 1,#segments do
        if segments[i].done then
            x = display.newLine(segments[i].startPoint.x,segments[i].startPoint.y,segments[i].endPoint.x,segments[i].endPoint.y)
            x:setColor( 255, 0, 0, 255 )
            x.width = 1
            table.insert(graphics, x)
        end    
    end
end

Runtime:addEventListener( "enterFrame", voronoi )