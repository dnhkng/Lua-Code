--[[
 
Copyright (c) 2010 David Ng
 
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
 
Based of the work of  Paul Bourke (1989), Efficient Triangulation 
Algorithm Suitable for Terrain Modelling.
http://local.wasp.uwa.edu.au/~pbourke/papers/triangulate/index.html
 
--]]
 
function delaunay(points_list)
    local triangle_list = {}
    local numpoints = #points_list
    
    --Insertion sort by x
    local w = points_list[1].x
    for i = 1, numpoints do
        local p = points_list[i]
        local x = p.x
        if x < w then
            local j = i
            while j>1 and points_list[j -1].x > x do
                points_list[j] = points_list[j - 1]
                j = j - 1
            end    
            points_list[ j ] = p;
        else
            w = x
        end    
    end
 
 
    --Create Supertriangle
    table.insert(points_list, {x = -5000, y = -5000})
    table.insert(points_list, {x = 5000, y = 0})
    table.insert(points_list, {x = 0, y = 5000})
    table.insert(triangle_list, {numpoints+1,numpoints+2,numpoints+3})
 
    local function inCircle(point, triangle_counter)
                --[[
                '''Series of calculations to check if a certain point lies inside lies inside the circumcircle
                made up by points in triangle (x1,y1) (x2,y2) (x3,y3)'''
                #adapted from Dimitrie Stefanescu's Rhinoscript version
                
                #Return TRUE if the point (xp,yp) 
                #The circumcircle centre is returned in (xc,yc) and the radius r
                #NOTE: A point on the edge is inside the circumcircle --]]
        if triangle_list[triangle_counter].done then
            return false
        end    
 
                local xp = point.x
                local yp = point.y
 
                if  triangle_list[triangle_counter].r then
 
            
                    local r = triangle_list[triangle_counter].r
                    local xc = triangle_list[triangle_counter].xc
                    local yc = triangle_list[triangle_counter].yc
                 
                    local dx = xp - xc
                local dy = yp - yc
                local rsqr = r*r
                local drsqr = dx * dx + dy * dy
            
            if xp > xc + r then
                triangle_list[triangle_counter].done = true
            end    
            
                if drsqr  numpoints then
                table.remove(triangle_list,i)
                i = i-1 
            end
        i = i+1
    end
    points_list[numpoints+1] = nil
    points_list[numpoints+2] = nil    
    points_list[numpoints+3] = nil  
    
    return triangle_list
end
 
   
 
stars = {}
lines = {}
points_list = {}
speed_list = {}
for i = 1,30 do
    points_list[i] = {x = math.random(0,768),y = math.random(0,1024),dx = math.random(-2,2), dy = math.random(-2,2)}
end
 
 
function stars:enterFrame( event )
 
    for i = #lines,1,-1 do
        lines[i]:removeSelf()
        lines[i] = nil
    end    
    lines = {}
    
    
    
    for i = 1,#points_list do
 
        points_list[i].x =  points_list[i].x + points_list[i].dx
        if points_list[i].x < 0 then
            points_list[i].x = 0
            points_list[i].dx = -1*points_list[i].dx
        end
        if points_list[i].x > 768 then
            points_list[i].x = 768
            points_list[i].dx = -1*points_list[i].dx
        end
        
        points_list[i].y =  points_list[i].y + points_list[i].dy
        if points_list[i].y < 0 then
            points_list[i].y = 0
            points_list[i].dy = -1*points_list[i].dy
        end
        if points_list[i].y > 1024 then
            points_list[i].y = 1024
            points_list[i].dy = -1*points_list[i].dy
        end
            
    end
 
    local tri = delaunay(points_list)
 
    ---[[
        for i = 1, #tri do
            local x
 
        x = display.newLine(points_list[tri[i][1] ].x, points_list[tri[i][1] ].y, points_list[tri[i][2] ].x, points_list[tri[i][2] ].y)
        x:setColor( 255, 0, 255, 255 )
        x.width = 3
        table.insert(lines, x)
        x = nil
        x = display.newLine(points_list[tri[i][2] ].x, points_list[tri[i][2] ].y, points_list[tri[i][3] ].x, points_list[tri[i][3] ].y)
        x:setColor( 255, 255, 0, 255 )
        x.width = 3 
        table.insert(lines, x)
        x = nil
        x = display.newLine(points_list[tri[i][3] ].x, points_list[tri[i][3] ].y, points_list[tri[i][1] ].x, points_list[tri[i][1] ].y)
        x:setColor( 0, 255, 255, 255 )
        x.width = 3
        table.insert(lines, x)
        x = nil
    end
    --]]
 
end    
 
 
--stars:enterFrame( )
Runtime:addEventListener( "enterFrame", stars )