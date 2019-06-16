struct Move
    source :: UInt64
    target :: UInt64
    piece_type :: String
    capture_type :: String
    promotion_type :: String
    enpassant_square :: UInt64
    castling_type :: String
end


function validate_move(board::Bitboard, move::Move, color::String="white")
    board = move_piece(board, move, color)
    board = update_attacked(board)
    in_check = king_in_check(board, color)
    board = unmove_piece(board, move, color)
    # board = update_attacked(board)
    return ~in_check
end


# function validate_move(board::Bitboard, move::Move, color::String="white")
#     newb = deepcopy(board)
#     newb = move_piece(newb, move, color)
#     newb = update_attacked(newb)
#     in_check = king_in_check(newb, color)
#     # board = unmove_piece(board, move, color)
#     # board = update_attacked(board)
#     return ~in_check
# end


function get_all_moves(board::Bitboard, color::String="white")
    valid_moves = Array{Move,1}()
    valid_moves = get_non_sliding_pieces_list(valid_moves, board,
        "king", color)
    valid_moves = get_non_sliding_pieces_list(valid_moves, board,
        "night", color)
    valid_moves = get_pawns_list(valid_moves, board, color)
    valid_moves = get_sliding_pieces_list(valid_moves, board, "queen", color)
    valid_moves = get_sliding_pieces_list(valid_moves, board, "rook", color)
    return get_sliding_pieces_list(valid_moves, board, "bishop", color)
end


function print_moves(moves)
    for move in moves
        s = UINT2PGN[move.source]
        t = UINT2PGN[move.target]
        println(move.piece_type, " ", s, " ", t)
    end
end


function get_all_valid_moves(board::Bitboard, color::String="white")
    moves = get_all_moves(board, color)
    valid_moves = Array{Move,1}()
    for move in moves
        if validate_move(board, move, color)
            push!(valid_moves, move)
        end
    end
    return valid_moves
end


function get_non_sliding_pieces_list(piece_moves::Array{Move,1},
    board::Bitboard, piece_type::String, color::String="white")

    if color == "white"
        same = board.white
        other = board.black
        if piece_type == "king"
            pieces = board.K
            home_square = WHITE_KING_HOME
        else
            pieces = board.N
        end
        opponent_color = "black"
    else
        same = board.black
        other = board.white
        if piece_type == "king"
            pieces = board.k
            home_square = BLACK_KING_HOME
        else
            pieces = board.n
        end
        opponent_color = "white"
    end

    if piece_type == "king"
        piece_dict = KING_MOVES

        if pieces == home_square
            if color == "white"
                if ~board.white_king_moved
                    if board.white_can_castle_kingside == true
                        if board.free & F1 != EMPTY &&
                            board.free & G1 != EMPTY &&
                            H1 in board.R
                            if ~square_in_check(board, E1, color) &&
                                ~square_in_check(board, F1, color)
                                push!(piece_moves, Move(pieces, G1,
                                    piece_type, "none", "none", EMPTY, "K"))
                            end
                        end
                    end
                    if board.white_can_castle_queenside == true
                        if board.free & D1 != EMPTY &&
                            board.free & C1 != EMPTY &&
                            board.free & B1 != EMPTY &&
                            A1 in board.R
                            if ~square_in_check(board, E1, color) &&
                                ~square_in_check(board, D1, color)
                                push!(piece_moves, Move(pieces, C1,
                                    piece_type, "none", "none", EMPTY, "Q"))
                            end
                        end
                    end
                end
            else
                if ~board.black_king_moved
                    if board.black_can_castle_kingside == true
                        if board.free & F8 != EMPTY &&
                            board.free & G8 != EMPTY &&
                            H8 in board.r
                            if ~square_in_check(board, E8, color) &&
                                ~square_in_check(board, F8, color)
                                push!(piece_moves, Move(pieces, G8,
                                    piece_type, "none", "none", EMPTY, "k"))
                            end
                        end
                    end
                    if board.black_can_castle_queenside == true
                        if board.free & D8 != EMPTY &&
                            board.free & C8 != EMPTY &&
                            board.free & B8 != EMPTY &&
                            A8 in board.r
                            if ~square_in_check(board, E8, color) &&
                                ~square_in_check(board, D8, color)
                                push!(piece_moves, Move(pieces, C8,
                                    piece_type, "none", "none", EMPTY, "q"))
                            end
                        end
                    end
                end
            end
        end
    else
        piece_dict = NIGHT_MOVES
    end

    for piece in pieces
        for move in piece_dict[piece]
            if move & same == EMPTY && move & other == EMPTY
                push!(piece_moves, Move(piece, move,
                    piece_type, "none", "none", EMPTY, "-"))
            elseif move & same == EMPTY && move & other != EMPTY
                taken_piece = find_piece_type(board, move, opponent_color)
                push!(piece_moves, Move(piece, move,
                    piece_type, taken_piece, "none", EMPTY, "-"))
            end
        end
    end
    return piece_moves
end


function find_piece_type(board::Bitboard, ui::UInt64, color::String)
    if color == "white"
        if ui == board.K
            return "king"
        elseif ui in board.Q
            return "queen"
        elseif ui in board.R
            return "rook"
        elseif ui in board.P
            return "pawn"
        elseif ui in board.B
            return "bishop"
        elseif ui in board.N
            return "night"
        else
            return "none"
        end
    else
        if ui == board.k
            return "king"
        elseif ui in board.q
            return "queen"
        elseif ui in board.r
            return "rook"
        elseif ui in board.p
            return "pawn"
        elseif ui in board.b
            return "bishop"
        elseif ui in board.n
            return "night"
        else
            return "none"
        end
    end
end


function get_sliding_pieces_list(piece_moves::Array{Move,1}, board::Bitboard,
    piece_type::String, color::String="white")

    if color == "white"
        same = board.white
        other = board.black
        if piece_type == "queen"
            pieces = board.Q
        elseif piece_type == "rook"
            pieces = board.R
        elseif piece_type == "bishop"
            pieces = board.B
        end
        opponent_color = "black"
    else
        same = board.black
        other = board.white
        if piece_type == "queen"
            pieces = board.q
        elseif piece_type == "rook"
            pieces = board.r
        elseif piece_type == "bishop"
            pieces = board.b
        end
        opponent_color = "white"
    end

    if piece_type == "queen"
        attack_fun = star_attack
    elseif piece_type == "rook"
        attack_fun = orthogonal_attack
    elseif piece_type == "bishop"
        attack_fun = cross_attack
    end

    moves = Array{UInt64,1}()
    edges = Array{UInt64,1}()
    for piece in pieces
        moves, edges = attack_fun(moves, edges, board.taken, piece)
        while length(moves) > 0
            push!(piece_moves, Move(piece, pop!(moves), piece_type,
                "none", "none", EMPTY, "-"))
        end
        while length(edges) > 0
            edge = pop!(edges)
            if edge & same == EMPTY && edge & other == EMPTY
                push!(piece_moves, Move(piece, edge, piece_type,
                                        "none", "none", EMPTY, "-"))
            elseif edge & same == EMPTY && edge & other != EMPTY
                taken_piece = find_piece_type(board, edge, opponent_color)
                push!(piece_moves, Move(piece, edge, piece_type,
                                        taken_piece, "none", EMPTY, "-"))
            end
        end
    end
    return piece_moves
end


function remove_from_square(b::UInt64, s::UInt64)
    return xor(b, s)
end


function remove_from_square(bs::Array{UInt64,1}, s::UInt64)
    filter!(e -> e != s, bs)
    return bs
end


function add_to_square(b::UInt64, s::UInt64)
    return b |= s
end


function add_to_square(bs::Array{UInt64,1}, s::UInt64)
    push!(bs, s)
    return bs
end


function update_from_to_squares(b::UInt64, s::UInt64, t::UInt64)
    b = remove_from_square(b, s)
    b = add_to_square(b, t)
    return b
end


function update_from_to_squares(bs::Array{UInt64,1}, s::UInt64, t::UInt64)
    bs = remove_from_square(bs, s)
    bs = add_to_square(bs, t)
    return bs
end


function update_castling_rights(board::Bitboard)
    if board.K == E1
        board.white_king_moved = false
    end
    if A1 in board.R
        board.white_can_castle_queenside = true
    end
    if H1 in board.R
        board.white_can_castle_kingside = true
    end
    if board.k == E8
        board.black_king_moved = false
    end
    if A8 in board.r
        board.black_can_castle_queenside = true
    end
    if H8 in board.r
        board.black_can_castle_kingside = true
    end
    for move in board.game
        if move == "whitekinge1"
            board.white_king_moved = true
        elseif move == "whiterooka1"
            board.white_can_castle_queenside = false
        elseif move == "whiterookh1"
            board.white_can_castle_kingside = false
        elseif move == "blackkinge8"
            board.black_king_moved = true
        elseif move == "blackrooka8"
            board.black_can_castle_queenside = false
        elseif move == "blackrookh8"
            board.black_can_castle_kingside = false
        end
    end
    return board
end


function update_attacked(board::Bitboard)
    board.A[1] = EMPTY
    for p in board.P
        for a in WHITE_PAWN_ATTACK[p]
            board.A[1] |= a
        end
    end
    board.A[2] = EMPTY
    for n in board.N
        for a in NIGHT_MOVES[n]
            board.A[2] |= a
        end
    end
    board.A[3] = EMPTY
    for q in board.Q
        board.A[3] |= ORTHO_MASKS[q] | DIAG_MASKS[q]
    end
    board.A[4] = EMPTY
    for r in board.R
        board.A[4] |= ORTHO_MASKS[r]
    end
    board.A[5] = EMPTY
    for b in board.B
        board.A[5] |= DIAG_MASKS[b]
    end
    board.white_attacks = EMPTY
    for i = 1:5
        board.white_attacks |= board.A[i]
    end

    # black
    board.a[1] = EMPTY
    for p in board.p
        for a in BLACK_PAWN_ATTACK[p]
            board.a[1] |= a
        end
    end
    board.a[2] = EMPTY
    for n in board.n
        for a in NIGHT_MOVES[n]
            board.a[2] |= a
        end
    end
    board.a[3] = EMPTY
    for q in board.q
        board.a[3] |= ORTHO_MASKS[q] | DIAG_MASKS[q]
    end
    board.a[4] = EMPTY
    for r in board.r
        board.a[4] |= ORTHO_MASKS[r]
    end
    board.a[5] = EMPTY
    for b in board.b
        board.a[5] |= DIAG_MASKS[b]
    end
    board.black_attacks = EMPTY
    for i = 1:5
        board.black_attacks |= board.a[i]
    end

    return board
end


function move_piece(b::Bitboard, m::Move, color::String="white")
    push!(b.game, color*m.piece_type*UINT2PGN[m.source])

    if color == "white"
        b.white = update_from_to_squares(b.white, m.source, m.target)
        b.taken = update_from_to_squares(b.taken, m.source, m.target)

        if m.capture_type != "none"
            b.black = remove_from_square(b.black, m.target)
            if m.capture_type == "pawn"
                b.p = remove_from_square(b.p, m.target)
            elseif m.capture_type == "night"
                b.n = remove_from_square(b.n, m.target)
            elseif m.capture_type == "bishop"
                b.b = remove_from_square(b.b, m.target)
            elseif m.capture_type == "queen"
                b.q = remove_from_square(b.q, m.target)
            elseif m.capture_type == "rook"
                b.r = remove_from_square(b.r, m.target)
            end
        end

        if m.piece_type == "pawn"
            if m.target == b.enpassant_square
                b.black = remove_from_square(b.black, m.target >> 8)
                b.p = remove_from_square(b.p, m.target >> 8)
                b.taken = remove_from_square(b.taken, m.target >> 8)
                b.enpassant_done = true
            else
                b.enpassant_done = false
                if m.enpassant_square != EMPTY
                    b.enpassant_square = m.enpassant_square
                end
            end
            b.P = update_from_to_squares(b.P, m.source, m.target)
        elseif m.piece_type == "night"
            b.N = update_from_to_squares(b.N, m.source, m.target)
        elseif m.piece_type == "bishop"
            b.B = update_from_to_squares(b.B, m.source, m.target)
        elseif m.piece_type == "queen"
            b.Q = update_from_to_squares(b.Q, m.source, m.target)
        elseif m.piece_type == "rook"
            b.R = update_from_to_squares(b.R, m.source, m.target)
        elseif m.piece_type == "king"
            b.K = update_from_to_squares(b.K, m.source, m.target)
            if m.castling_type != "-"
                if m.castling_type == "K"
                    b.R = update_from_to_squares(b.R, H1, F1)
                    b.white = update_from_to_squares(b.white, H1, F1)
                    b.taken = update_from_to_squares(b.taken, H1, F1)
                elseif m.castling_type == "Q"
                    b.R = update_from_to_squares(b.R, A1, D1)
                    b.white = update_from_to_squares(b.white, A1, D1)
                    b.taken = update_from_to_squares(b.taken, A1, D1)
                end
            end
        end

        if m.promotion_type != "none"
            b.P = remove_from_square(b.P, m.target)
            if m.promotion_type == "queen"
                b.Q = add_to_square(b.Q, m.target)
            elseif m.promotion_type == "rook"
                b.R = add_to_square(b.R, m.target)
            elseif m.promotion_type == "night"
                b.N = add_to_square(b.N, m.target)
            elseif m.promotion_type == "bishop"
                b.B = add_to_square(b.B, m.target)
            end
        end
    else
        b.black = update_from_to_squares(b.black, m.source, m.target)
        b.taken = update_from_to_squares(b.taken, m.source, m.target)

        if m.capture_type != "none"
            b.white = remove_from_square(b.white, m.target)
            if m.capture_type == "pawn"
                b.P = remove_from_square(b.P, m.target)
            elseif m.capture_type == "night"
                b.N = remove_from_square(b.N, m.target)
            elseif m.capture_type == "bishop"
                b.B = remove_from_square(b.B, m.target)
            elseif m.capture_type == "queen"
                b.Q = remove_from_square(b.Q, m.target)
            elseif m.capture_type == "rook"
                b.R = remove_from_square(b.R, m.target)
            end
        end

        if m.piece_type == "pawn"
            if m.target == b.enpassant_square
                b.white = remove_from_square(b.white, m.target << 8)
                b.P = remove_from_square(b.P, m.target << 8)
                b.taken = remove_from_square(b.taken, m.target << 8)
                b.enpassant_done = true
            else
                b.enpassant_done = false
                if m.enpassant_square != EMPTY
                    b.enpassant_square = m.enpassant_square
                end
            end
            b.p = update_from_to_squares(b.p, m.source, m.target)
        elseif m.piece_type == "night"
            b.n = update_from_to_squares(b.n, m.source, m.target)
        elseif m.piece_type == "bishop"
            b.b = update_from_to_squares(b.b, m.source, m.target)
        elseif m.piece_type == "queen"
            b.q = update_from_to_squares(b.q, m.source, m.target)
        elseif m.piece_type == "rook"
            b.r = update_from_to_squares(b.r, m.source, m.target)
        elseif m.piece_type == "king"
            b.k = update_from_to_squares(b.k, m.source, m.target)
            if m.castling_type != "-"
                if m.castling_type == "k"
                    b.r = update_from_to_squares(b.r, H8, F8)
                    b.black = update_from_to_squares(b.black, H8, F8)
                    b.taken = update_from_to_squares(b.taken, H8, F8)
                elseif m.castling_type == "q"
                    b.r = update_from_to_squares(b.r, A8, D8)
                    b.black = update_from_to_squares(b.black, A8, D8)
                    b.taken = update_from_to_squares(b.taken, A8, D8)
                end
            end
        end
        
        if m.promotion_type != "none"
            b.p = remove_from_square(b.p, m.target)
            if m.promotion_type == "queen"
                b.q = add_to_square(b.q, m.target)
            elseif m.promotion_type == "rook"
                b.r = add_to_square(b.r, m.target)
            elseif m.promotion_type == "night"
                b.n = add_to_square(b.n, m.target)
            elseif m.promotion_type == "bishop"
                b.b = add_to_square(b.b, m.target)
            end
        end
    end
    b.free = ~b.taken
    
    # b = update_attacked(b)
    # return update_castling_rights(b)
    return b
end


# function unmove_piece(board::Bitboard, move::Move, color::String="white")
#     if color == "white"
#         board.white = update_from_to_squares(board.white, move.target,
#             move.source)
#         board.taken = update_from_to_squares(board.taken, move.target,
#             move.source)

#         if move.piece_type == "pawn"
#             if board.enpassant_done
#                 board.black = add_to_square(board.black, move.target >> 8)
#                 board.p = add_to_square(board.p, move.target >> 8)
#                 board.taken = add_to_square(board.taken, move.target >> 8)
#                 board.enpassant_done = false
#                 board.enpassant_square = move.target
#             end
#             board.P = update_from_to_squares(board.P, move.target, move.source)
#         elseif move.piece_type == "night"
#             board.N = update_from_to_squares(board.N, move.target, move.source)
#         elseif move.piece_type == "bishop"
#             board.B = update_from_to_squares(board.B, move.target, move.source)
#         elseif move.piece_type == "queen"
#             board.Q = update_from_to_squares(board.Q, move.target, move.source)
#         elseif move.piece_type == "rook"
#             board.R = update_from_to_squares(board.R, move.target, move.source)
#         elseif move.piece_type == "king"
#             board.K = update_from_to_squares(board.K, move.target, move.source)
#             if move.castling_type != "-"
#                 if move.castling_type == "K"
#                     board.R = update_from_to_squares(board.R, F1, H1)
#                     board.white = update_from_to_squares(board.white, F1, H1)
#                     board.taken = update_from_to_squares(board.taken, F1, H1)
#                 elseif move.castling_type == "Q"
#                     board.R = update_from_to_squares(board.R, D1, A1)
#                     board.white = update_from_to_squares(board.white, D1, A1)
#                     board.taken = update_from_to_squares(board.taken, D1, A1)
#                 end
#             end
#         end

#         if move.capture_type != "none"
#             board.black = add_to_square(board.black, move.target)
#             board.taken = add_to_square(board.taken, move.target)
#             if move.capture_type == "pawn"
#                 board.p = add_to_square(board.p, move.target)
#             elseif move.capture_type == "night"
#                 board.n = add_to_square(board.n, move.target)
#             elseif move.capture_type == "bishop"
#                 board.b = add_to_square(board.b, move.target)
#             elseif move.capture_type == "queen"
#                 board.q = add_to_square(board.q, move.target)
#             elseif move.capture_type == "rook"
#                 board.r = add_to_square(board.r, move.target)
#             end
#         end
#     else
#         board.black = update_from_to_squares(board.black, move.target,
#             move.source)
#         board.taken = update_from_to_squares(board.taken, move.target,
#             move.source)

#         if move.piece_type == "pawn"
#             if board.enpassant_done
#                 board.white = add_to_square(board.white, move.target << 8)
#                 board.P = add_to_square(board.P, move.target << 8)
#                 board.taken = add_to_square(board.taken, move.target << 8)
#                 board.enpassant_done = false
#                 board.enpassant_square = move.target
#             end
#             board.p = update_from_to_squares(board.p, move.target, move.source)
#         elseif move.piece_type == "night"
#             board.n = update_from_to_squares(board.n, move.target, move.source)
#         elseif move.piece_type == "bishop"
#             board.b = update_from_to_squares(board.b, move.target, move.source)
#         elseif move.piece_type == "queen"
#             board.q = update_from_to_squares(board.q, move.target, move.source)
#         elseif move.piece_type == "rook"
#             board.r = update_from_to_squares(board.r, move.target, move.source)
#         elseif move.piece_type == "king"
#             board.k = update_from_to_squares(board.k, move.target, move.source)
#             if move.castling_type != "-"
#                 if move.castling_type == "k"
#                     board.r = update_from_to_squares(board.r, F8, H8)
#                     board.black = update_from_to_squares(board.black, F8, H8)
#                     board.taken = update_from_to_squares(board.taken, F8, H8)
#                 elseif move.castling_type == "q"
#                     board.r = update_from_to_squares(board.r, D8, A8)
#                     board.black = update_from_to_squares(board.black, D8, A8)
#                     board.taken = update_from_to_squares(board.taken, D8, A8)
#                 end
#             end
#         end

#         if move.capture_type != "none"
#             board.white = add_to_square(board.white, move.target)
#             board.taken = add_to_square(board.taken, move.target)
#             if move.capture_type == "pawn"
#                 board.P = add_to_square(board.P, move.target)
#             elseif move.capture_type == "night"
#                 board.N = add_to_square(board.N, move.target)
#             elseif move.capture_type == "bishop"
#                 board.B = add_to_square(board.B, move.target)
#             elseif move.capture_type == "queen"
#                 board.Q = add_to_square(board.Q, move.target)
#             elseif move.capture_type == "rook"
#                 board.R = add_to_square(board.R, move.target)
#             end
#         end
#     end
#     board.free = ~board.taken
#     pop!(board.game)
#     # board = update_attacked(board)
#     # return update_castling_rights(board)
#     return board
# end
