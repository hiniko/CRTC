class CRTC::Client

    def process_response(resp, format='s', email=false)
        data = {}   
        # Find what kind of reponse we got
        case resp
            when /200 Ok/
                data[:status] = :ok
            when /401/ 
                data[:status] = :forbidden
            when /does not exist/
                data[:status] = :not_exist
            when /invalid attachment/
                data[:status] = :invalid_attachment 
            when /not related/
                data[:status] = :not_related
            when /No matching results/
                data[:status] = :no_macth 
            when /Invalid query/
                data[:status] = :invalid_query
            when nil 
                data[:status] = :error
                data[:error_msg] = "Response was nil!"
            else 
                data[:status] = :error
                data[:error_msg] = "I don't know what this response is!"
        end
        # parse resp accordingly
        if ! email
            case format
                when 's'
                   data[:data] = parse_data(resp)
                when 'l'
                   data[:data] =  parse_long_data(resp)
            end
        else
            data[:data] = parse_email(resp)
        end
    
      return data
    end

    def parse_id(id)
      return (id.class == String)? id.to_i : 0
    end

    def parse_long_data(data)
      items = [] 
      data.gsub!(/^RT\/.*/, '')
      data.sub!(/^#.*/, '')
      raw_parts = data.split(/\n--\n/)
      raw_parts.each do |part|
        item = {}
        if part =~ /Content:/
          content = part.slice!(/^Content:(.*?)\n\n/m).to_s
          content.sub!(/^Content:/, '')
          content.gsub!(/^\s{9}/, '')
          content.gsub!(/^(\s+)/, '')
          item[:content] = content 
        end
        if part =~ /Attachements:/ 
          attachments = part.slice!(/^Attachments:(.*?)\n\n/m).to_s
          attachments.sub!(/^Attachments:/, '')
          attachments.gsub!(/^\s+/m, '')
          item[:attachements] = parse_data(attachments)
        end
        item[:meta] = parse_data(part) 
        items << item
      end
      return items if items.length > 1
      return items[0]
    end

    def parse_data(data)
      hash = {} 
      data.split("\n").each do |line|
        next if line.empty?
        next if line.match(/^RT\//)
        next if line.match(/^#/)
        matches = line.match(/^([\w\.\{\} ]+): (.*)/)
        next if matches == nil
        if matches.length > 1
          k,v = matches.captures
          k.gsub!(' ', '_') if k.match(/^CF/)
          k.gsub!(/^(\s+)/, '')
          if k == 'id'
              v.gsub!('ticket/', '')
          end
          hash[k]=v
        else
          k = matches.captures[0]
          hash[k] = ''
        end
     end
     return hash
    end

    def parse_email(resp)
      data = {}
      meta, mail = resp.split('Headers:')
      data[:meta] = parse_data(meta)
      mail.sub!(/^Headers:/, '')
      mail.sub!(/^Content:/, '')
      mail.gsub!(/^\s{9}/, '')
      mail.gsub!(/^ {1}/, '') 
      data[:email] = Mail.read_from_string mail
      return data 
    end

end
