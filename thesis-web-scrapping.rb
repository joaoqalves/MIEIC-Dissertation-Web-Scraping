# encoding: UTF-8
require 'nokogiri'
require 'open-uri'
require 'csv'
require 'set'

STUDENT_ID = "112374" # INSERT YOUR STUDENT ID HERE
STUDENT_NUMBER =  "200801722" # INSERT YOUR STUDENT NUMBER HERE
# INSERT YOUR COOKIE BELOW
COOKIE = "FCNAUPHTTP_SESSION=10139674; FCUPHTTP_SESSION=29626930; FDUPHTTP_SESSION=13588674; FEPHTTP_SESSION=47986428; _pk_ref.5.7cdc (...)"

BASE_URL = "https://sigarra.up.pt/feup/pt/"
PROCESS_NUMBER = "18232"
INDEX_URL = "#{BASE_URL}estagios_empresas.lista_propostas_processo?p_aluno_id=#{STUDENT_ID}&p_processo=#{PROCESS_NUMBER}&pv_perfil=ALU"
PROFESSOR_URL = "#{BASE_URL}estagios_alunos.lista_propostas?p_aluno=#{STUDENT_NUMBER}&p_processo=#{PROCESS_NUMBER}&pv_perfil=ALU&p_doc_codigo="
DISSERTATION_URL = "#{BASE_URL}estagios_empresas.ver_dados_proposta?pv_perfil=ALU&p_id="

PROFESSORS_REGEX = "func_geral.formview?p_codigo"
COMPANIES_REGEX = "pct_user"
THESIS_REGEX = "estagios_empresas.ver_dados_proposta"

def get_ids_in_link_by_href_regex(doc, link_regex)
	ids = Set.new
	doc.xpath('//a[@href]').each do |link|
	  if link['href'] =~ /#{Regexp.quote(link_regex)}/
		  ids.add link['href'].split("=")[1].split("&").first
	  end
	end
	ids.to_a
end

def get_html(url)
	Nokogiri::HTML(open(url, "Cookie" => COOKIE))
end

def get_thesis_html_pages()
	dissertation_ids = []
	dissertation_pages = []
	index_page = get_html(INDEX_URL)
	professors_ids = get_ids_in_link_by_href_regex(index_page, PROFESSORS_REGEX)
	companies_ids = get_ids_in_link_by_href_regex(index_page, COMPANIES_REGEX)
	
	professors_ids.each do |p_id|
	  proposed_dissertation_page = get_html(PROFESSOR_URL+p_id)
	  dissertation_ids += get_ids_in_link_by_href_regex(proposed_dissertation_page, THESIS_REGEX)
	end
	
	companies_ids.each do |pct|
	  proposed_dissertation_page = get_html(PROFESSOR_URL+pct)
	  dissertation_ids += get_ids_in_link_by_href_regex(proposed_dissertation_page, THESIS_REGEX)
	end
	
	dissertation_ids.each do |thesis|
	  dissertation_pages << get_html(DISSERTATION_URL+thesis)
	end
	
	dissertation_pages
	
end

def dissertations_pages_to_array_of_hashes(dissertations_pages)
	all_dissertations = Array.new
	dissertations_pages.each do |dis|
		dissertation = Hash.new
		dis.css('#conteudo > table tr').each do |tab|
			key = nil
			value = nil
			tab.css('td').each_with_index do |t,index|
				key = t.text if index == 0
				value = t.text if index == 1
				dissertation[key] = value if index == 1
			end
		end
		all_dissertations << dissertation
	end
	all_dissertations
end

dissertation_pages = get_thesis_html_pages()
dissertations = dissertations_pages_to_array_of_hashes(dissertation_pages)

CSV.open("dissertation-professors.csv", "wb") do |csv|
	dissertations.each do |d|
		values = Array.new
		d.each_pair do |k,v|
			values << v
		end
		csv << values
	end
end
