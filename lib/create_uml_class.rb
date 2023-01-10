require "tempfile"

CStruct = Struct.new(:type,
                     :name,
                     :block_count,
                     :var_list,
                     :method_list,
                     :inherit_list,
                     :composition_list)

def print_uml(out, out_list)
  out_list.each do |o_list|
    if o_list.type == :class_start
      # nop
    elsif o_list.type == :module_start
      out.push "namespace #{o_list.name} {"
    elsif o_list.type == :class_end
      pp o_list if o_list.name == ""
      out.push "class #{o_list.name} {"
      # インスタンス変数の出力
      o_list.var_list.uniq.each do |iv|
        out.push iv
      end
      # メソッドの出力
      o_list.method_list.each do |ml|
        out.push ml
      end
      out.push "}"
      # 継承リストの出力
      o_list.inherit_list.each do |ih|
        out.push "#{o_list.name} --|> #{ih}"
      end
      # compo
      o_list.composition_list.uniq.each do |co|
        out.push "#{o_list.name} *-- #{co}"
      end
    elsif o_list.type == :module_end
      # インスタンス変数がある場合はモジュール名と同じクラスを定義
      if o_list.var_list.size != 0 or
         o_list.method_list.size != 0 or
         o_list.inherit_list.size != 0 or
         o_list.composition_list.size != 0
        pp o_list if o_list.name == ""
        out.push "class #{o_list.name} {"
        # インスタンス変数の出力
        o_list.var_list.uniq.each do |iv|
          out.push iv
        end
        # メソッドの出力
        o_list.method_list.each do |ml|
          out.push ml
        end
        out.push "}"
        # 継承リストの出力
        o_list.inherit_list.each do |ih|
          out.push "#{o_list.name} --|> #{ih}"
        end
        # compo
        o_list.composition_list.uniq.each do |co|
          out.push "#{o_list.name} *-- #{co}"
        end
      end
      out.push "}"
    else
      # error
      puts "error!"
    end
  end
  return out
end

def delete_here_doc(buf)
  new_buf = []
  here_doc = false
  here_word = ""
  buf.each_line do |line|
    if line =~ /(<<|<<~|<<-)[A-Z]+/
      here_doc = true
      here_word = line.match(/(<<|<<~|<<-)[A-Z]+/).to_s.gsub(/[<~-]/, "")
    end
    if here_word != "" and line =~ Regexp.new("^\s*#{here_word}$")
      here_word = ""
      here_doc = false
      pp line
    end
    if here_doc == false
      new_buf.push line
    else
      pp line
    end
  end
  return new_buf.join("")
end

def create_uml_class(in_dir, out_file)
  out = []
  out.push "@startuml"

  puts "in_dir = #{in_dir}"
  main_composition_list = []
  main_method_list = []
  global_var = []

  Dir.glob("#{in_dir}/**/*.{rb,ru}") do |f|
    puts f
    buf = ""
    Tempfile.create("rufo") do |tmp_file|
      FileUtils.cp(f, tmp_file.path)
      open("|rufo #{tmp_file.path}") do |f|
        if f.read =~ /error/
          puts "rufo error #{f}"
          return
        else
          buf = File.binread tmp_file.path
        end
      end
    end

    # コメント削除
    buf.gsub!(/(([\/\"\'].*?[\/\"\'])|([^\/\"\'\)\s]*#.+?$))/) do |m|
      if m[0] == "#" and m[0] != "{"
        #puts "comment #{m}"
        # コメント
        ""
      else
        #puts "not comment #{m}"
        # コメント以外
        m
      end
    end
    # ヒアドキュメント削除
    buf = delete_here_doc(buf)

    out_list = []
    cstruct_list = []
    block_count = 0
    method_type = :public
    class_name = ""
    # ソースを解析
    buf.each_line do |line|
      next if line =~ /^$/  # 空行は対象外

      # ブロックの開始/終了
      indent_num = line.match(/^[ ]+/).to_s.size / 2
      if block_count == indent_num
        # 変化なし
      elsif block_count > indent_num
        # ブロックの終了
        block_count = indent_num
      else
        # ブロックの開始
        block_count = indent_num
      end

      #line.gsub!(/\".+\"/, "\"delete_string\"") # 文字列を削除
      if line =~ /^\s*class\s/
        unless line =~ /<</ # 特異クラスではない
          work = line.gsub(/class\s/, "")
          class_name = work.split("<")[0].to_s.chomp.match(/[A-Z][A-Za-z0-9_:]+/).to_s
          base_name = work.split("<")[1].to_s.chomp.match(/[A-Z][A-Za-z0-9_:]+/).to_s
          class_name.gsub!(/::/, ".")
          if out_list.size != 0 and out_list[-1].type == :class_start # classが連続している
            class_name = out_list[-1].name + "." + class_name
            out_list[-1].name = class_name
            cstruct_list[-1].name = class_name
          else
            out_list.push CStruct.new(:class_start, class_name, block_count, [], [], [], [])
            cstruct_list.push CStruct.new(:class_end, class_name, block_count, [], [], [], [])
          end
          pp line if class_name == ""
          if base_name != ""
            #base_name.gsub!(/::/, ".")
            cstruct_list[-1].inherit_list.push base_name
          end
        end
        next unless line =~ /end\s*$/ # 1行で終了しない場合
      elsif line =~ /^\s*module\s/
        module_name = line.split(" ")[1].to_s.chomp
        module_name.gsub!(/^[:]+/, "")
        module_name.gsub!(/::/, ".")
        out_list.push CStruct.new(:module_start, module_name, block_count, [], [], [], [])
        cstruct_list.push CStruct.new(:module_end, module_name, block_count, [], [], [], [])
        next unless line =~ /end\s*$/ # 1行で終了しない場合
      end

      if line =~ /^\s*private$/
        method_type = :private
      elsif line =~ /^\s*protected$/
        method_type = :protected
      elsif line =~ /^\s*public$/
        method_type = :public
      end

      if line =~ /^\s*def\s/
        # 関数名を取り出す
        method = line.chomp.gsub(/\s*def\s*/, "")
        unless method =~ /\(/
          # 関数名にカッコをつける
          sp = method.split(" ")
          if sp.size > 1
            method = sp[0].to_s + "(" + sp[1..-1].to_s + ")"
          else
            method = method + "()"
          end
        end
        if cstruct_list.size != 0
          method_list = cstruct_list[-1].method_list
          case method_type
          when :public
            method_list.push "+ #{method}"
          when :private
            method_list.push "- #{method}"
          when :protected
            method_list.push "# #{method}"
          end
        else
          main_method_list.push "+ #{method}"
        end
      end

      # composition_list
      line.match(/(([\/\"\')].*?\.new.*?[\/\"\'])|(?![\/\"\'])([a-zA-Z0-9_]+\.new))/) do |m|
        if m.to_s[0] != "/" and m.to_s[0] != "\"" and m.to_s[0] != "'"
          name = m.to_s.gsub(/\.new/, "").match(/[A-Z][A-Za-z0-9_]+/).to_s
          if name != ""
            if cstruct_list.size != 0
              cstruct_list[-1].composition_list.push name
            else
              main_composition_list.push "main *-- #{name}"
            end
          end
        end
      end

      # インスタンス変数
      if line =~ /\s*@\S+/
        if cstruct_list.size != 0
          line.match(/@[a-zA-Z0-9_]+/) { |m|
            instance_var = cstruct_list[-1].var_list
            val = m.to_s.gsub(/@/, "")
            case method_type
            when :public
              instance_var.push "+ #{val}"
            when :private
              instance_var.push "- #{val}"
            when :protected
              instance_var.push "# #{val}"
            end
          }
        end
      end

      # 外部変数
      line.match(/\$[a-zA-Z0-9_]+/) { |m|
        global_var.push "+ #{m.to_s}"
      }

      # クラスの終了
      if cstruct_list.size != 0
        if block_count == cstruct_list[-1].block_count # block_countが一致
          #puts "end of #{cstruct_list[-1].name}"
          out_list.push cstruct_list[-1]
          cstruct_list.slice!(-1) # 最後の要素を削除
        end
      end
      #puts "#{block_count} #{line.chomp}"
    end
    if block_count != 0
      # エラー
      puts f
      return ""
    end

    # UMLの出力
    out = print_uml(out, out_list)
  end

  if main_method_list.size != 0 or
     main_composition_list.size != 0 or
     main_method_list.size != 0
    out.push "class main {"
    main_method_list.each do |mml|
      out.push mml
    end
    # グローバル変数の出力
    global_var.uniq.each do |gv|
      out.push gv
    end
    out.push "}"
    main_composition_list.uniq.each do |mcl|
      out.push mcl
    end
  end

  out.push "@enduml"
  return out.join("\n")
end
