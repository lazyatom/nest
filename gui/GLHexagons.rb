

    L = Architecture::L
    R = Architecture::R
    P = Architecture::P
    H = Architecture::H

    def createArrowList()
        @arrowListID = GL.GenLists(1)
        GL.NewList(@arrowListID, GL::COMPILE)
                GL.Begin(GL::LINES)
                    GL.Vertex(-P+0.5,0,0.1) 
                    GL.Vertex(-P+0.5,H,0.1) 
                GL.End()
                GL.Begin(GL::LINE_STRIP)
                    GL.Vertex(-P+0.2,(H/2),0.1)
                    GL.Vertex(-P+0.5,H,0.1) 
                    GL.Vertex(-P+0.8,(H/2),0.1)
                GL.End()           
        GL.EndList()
    end
    
    def createOutlineList()
        @outlineListID = GL.GenLists(1)
        GL.NewList(@outlineListID, GL::COMPILE)
            # the top hexagon
            GL.Begin(GL::LINE_LOOP)
                GL.Vertex(-P,+H,0) # NW
                GL.Vertex(+P,+H,0) # NE
                GL.Vertex(+R,0,0) # E
                GL.Vertex(+P,-H,0) # SE
                GL.Vertex(-P,-H,0) # SW
                GL.Vertex(-R,0,0) # W
            GL.End()

            #the sides
            GL.Begin(GL::LINES)
                GL.Vertex(-P,+H,0) # NW
                GL.Vertex(-P,+H,-L) # NW
                GL.Vertex(+P,+H,0) # NE
                GL.Vertex(+P,+H,-L) # NE
                GL.Vertex(+R,0,0) # E
                GL.Vertex(+R,0,-L) # E
                GL.Vertex(+P,-H,0) # SE
                GL.Vertex(+P,-H,-L) # SE
                GL.Vertex(-P,-H,0) # SW
                GL.Vertex(-P,-H,-L) # SW
                GL.Vertex(-R,0,0) # W
                GL.Vertex(-R,0,-L) # W
            GL.End()

            #the bottom heagon
            GL.Begin(GL::LINE_LOOP)
                GL.Vertex(-P,+H,-L) # NW
                GL.Vertex(+P,+H,-L) # NE
                GL.Vertex(+R,0,-L) # E
                GL.Vertex(+P,-H,-L) # SE
                GL.Vertex(-P,-H,-L) # SW
                GL.Vertex(-R,0,-L) # W
            GL.End()
        GL.EndList()    
    end
    
        def createCellList()
        @cellListID = GL.GenLists(1);
        GL.NewList(@cellListID, GL::COMPILE)

            # the top hexagon
            GL.Begin(GL::TRIANGLE_FAN)
                GL.Vertex(0,0,0) # center
                GL.Vertex(-P,+H,0) # NW
                GL.Vertex(+P,+H,0) # NE
                GL.Vertex(+R,0,0) # E
                GL.Vertex(+P,-H,0) # SE
                GL.Vertex(-P,-H,0) # SW
                GL.Vertex(-R,0,0) # W
                GL.Vertex(-P,+H,0) #NW
            GL.End()

            #the sides
            GL.Begin(GL::QUAD_STRIP)
                GL.Vertex(-P,+H,0) # NW
                GL.Vertex(-P,+H,-L) # NW
                GL.Vertex(+P,+H,0) # NE
                GL.Vertex(+P,+H,-L) # NE
                GL.Vertex(+R,0,0) # E
                GL.Vertex(+R,0,-L) # E
                GL.Vertex(+P,-H,0) # SE
                GL.Vertex(+P,-H,-L) # SE
                GL.Vertex(-P,-H,0) # SW
                GL.Vertex(-P,-H,-L) # SW
                GL.Vertex(-R,0,0) # W
                GL.Vertex(-R,0,-L) # W
                GL.Vertex(-P,+H,0) #NW
                GL.Vertex(-P,+H,-L) #NW
            GL.End()


            #the bottom hexagon
            GL.Begin(GL::TRIANGLE_FAN)
                GL.Vertex(0,0,-L) # center
                GL.Vertex(-P,+H,-L) # NW
                GL.Vertex(+P,+H,-L) # NE
                GL.Vertex(+R,0,-L) # E
                GL.Vertex(+P,-H,-L) # SE
                GL.Vertex(-P,-H,-L) # SW
                GL.Vertex(-R,0,-L) # W
                GL.Vertex(-P,+H,-L) # NW
            GL.End()        
        GL.EndList();
    end