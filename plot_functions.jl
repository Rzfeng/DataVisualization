using PyPlot
using PlotRecipes
using PyCall
@pyimport networkx as nx

mainNodeList = []
mainEdgeList = []
function create_edge_node_matrix(graph::ModelGraph)

    numNodes = length(collectnodes(graph))

    numSubgraphs = length(getsubgraphlist(graph))
    subEdgeList = []

    count = 1

    #Find all the edges in the subgraph and add them to the list of edges
    for i in range(1, numSubgraphs)
        temp = Plasmo.PlasmoGraphBase.getsubgraphlist(graph)[i]
        tempEds = collectedges(temp)
        numTempEds = length(tempEds)
        for edge in getedges(temp)
            h = getindex(temp,edge)
            tempV = h.vertices
            v = collect(tempV)
            push!(subEdgeList, v)
            for k in range(1, length(v))
                n = getnode(temp, h.vertices[k])
                subIndex = getindex(temp, n)
                mainIndex = getindex(graph, n)
                subEdgeList[count][k] = mainIndex
            end
            count += 1
        end
    end

    #Get edges in the main graph
    mainEdgeList = subEdgeList
    numEdges = length(collectedges(graph))

    for edge in getedges(graph)
    #for i in range(1, numEdges)

        #h = getindex(graph, collectedges(graph)[i])
        h = getindex(graph,edge)
        tempV = h.vertices
        v = collect(tempV)
        push!(mainEdgeList, v)
    end
    #remove duplicate edges (i.e. if we have 1-4 4-1, remove 4-1 or 1-4)
    mainEdgeList = unique(mainEdgeList)

    #Get nodes in the main graph
    #for i in range(1, numNodes)
    for node in getnodes(graph)
        #h = collectnodes(graph)
        v = getindex(graph, node)
        push!(mainNodeList, v)
    end


    nodeList = mainNodeList
    edgeList = mainEdgeList

    numNodes = length(nodeList)
    numEdges = length(edgeList)

    #mE = edgeList
    g =zeros(numEdges, numNodes)

    for i in range(1, numEdges)
        temp = edgeList[i]
        for j in range(1, length(temp))
            findNode = temp[j]
            g[i, findNode] = 1
        end
    end

    matshow(g)
    return g, nodeList, edgeList
end

function plotSimpleGraph(graph::ModelGraph)
    #Create graph to be returned
    B = nx.Graph()


    #Get the number of distinct nodes and edges
    curMatrix, nodeList, edgeList = create_edge_node_matrix(graph)
    numColumns = size(curMatrix)[2]
    numRows = size(curMatrix)[1]

    #Add nodes to the bipartite graph
    for i in range(1, numColumns)
        B[:add_nodes_from]([nodeList[i]], bipartite = 0)
    end

    #add hypergraph edges to the bipartite graph
    for i in range(1, length(edgeList))
        if (length(edgeList[i]) > 2)
            cur = string(edgeList[i])
            B[:add_nodes_from]([cur], bipartite = 1)
        end
    end

    #add bipartite graph edges
    for i in range(1, length(edgeList))
        for j in range(1, length(edgeList[i]))
            if (length(edgeList[i]) == 2)
                curNode1 = edgeList[i][1]
                curNode2 = edgeList[i][2]
                B[:add_edges_from]([(curNode1, curNode2)])
            else
                curNode = edgeList[i][j]
                #println("curNode is ", curNode)
                curEdge = string(edgeList[i])
                #println("curEdge is ", curEdge)
                B[:add_edges_from]([(curNode, curEdge)])
            end
        end
    end
    PyPlot.clf()

    nx.draw(B, with_labels = true)
    return B
end



function plotThisGraph(graph::ModelGraph)
    #Create graph to be returned
    B = nx.Graph()

    #Get the number of distinct nodes and edges
    curMatrix, nodeList, edgeList = create_edge_node_matrix(graph)
    numColumns = size(curMatrix)[2]
    numRows = size(curMatrix)[1]

    #Add nodes to the bipartite graph
    for i in range(1, numColumns)
        B[:add_nodes_from]([nodeList[i]], bipartite = 0)
    end



    #add hypergraph edges to the bipartite graph
    for i in range(1, length(edgeList))
        cur = string(edgeList[i])
        B[:add_nodes_from]([cur], bipartite = 1)
    end

    #add bipartite graph edges
    for i in range(1, length(edgeList))
        for j in range(1, length(edgeList[i]))
            curNode = edgeList[i][j]
            #println("curNode is ", curNode)
            curEdge = string(edgeList[i])
            #println("curEdge is ", curEdge)
            B[:add_edges_from]([(curNode, curEdge)])
        end
    end



    PyPlot.clf()
    # Separate by group
    l, r = nx.bipartite[:sets](B)
    pos = Dict()

    #Update position for node from each group
    #Nodes on the left, edges on the right (flip the 1 and 2 to switch back)
    for (index, node) in enumerate(l)
        pos[node] = (1, index)
    end
    for (index, node) in enumerate(r)
        pos[node] = (2, index)
    end

    #draw the bipartite graph
    nx.draw(B, pos=pos, with_labels = true)
    nx.write_gexf(B, "test.gexf")
#    matshow(curMatrix)
    return B
end
