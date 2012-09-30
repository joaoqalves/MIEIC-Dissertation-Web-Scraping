
require 'nokogiri'
require 'open-uri'
require 'csv'

STUDENT_ID = "080509065" # INSERT YOUR STUDENT ID HERE
# INSERT YOUR COOKIE BELOW
COOKIE = "GPAG_CCORRENTE_GERAL_CONTA_CORRENTE_VIEW=0; __utma=130543245.768358309.1337265203.1337265203.1337265203.1; __utmz=130543245.1337265203.1.1.utmcsr=(direct)|utmccn=(direct)|utmcmd=(none); _pk_ref.5.7cdc=%5B%22%22%2C%22%22%2C1338834354%2C%22http%3A%2F%2Fupin.up.pt%2F%22%5D; _pk_id.5.7cdc=b0c5b8abeea6c398.1337209994.2.1338834354.1337210096.; _pk_ref.23.7cdc=%5B%22%22%2C%22%22%2C1338834354%2C%22http%3A%2F%2Fupin.up.pt%2F%22%5D; _pk_id.23.7cdc=b0c5b8abeea6c398.1337209994.2.1338834354.1337210096.; __atuvc=3|20,0|21,0|22,1|23; FEUPSI_SESSION=21027835; FEUPSI_SECURITY=G9p/3ieAGV9EYOj; FEUPHTTP_SESSION=458510911"

BASE_URL = "https://sigarra.up.pt/feup/"
INDEX_URL = "#{BASE_URL}ESTAGIOS_ALUNOS.LISTA_EMPRESAS?p_aluno=#{STUDENT_ID}&p_processo=1103"
PROFESSOR_URL = "#{BASE_URL}estagios_alunos.lista_propostas?p_aluno=#{STUDENT_ID}&p_processo=1103&p_doc_codigo="
COMPANY_URL = "#{BASE_URL}estagios_alunos.lista_propostas?p_aluno=#{STUDENT_ID}&p_processo=1103&p_inst_codigo="
DISSERTATION_URL = "#{BASE_URL}estagios_empresas.ver_dados_proposta?p_id="

PROFESSORS_REGEX = "p_doc_codigo"
COMPANIES_REGEX = "p_inst_codigo"
THESIS_REGEX = "estagios_empresas"

def get_ids_in_link_by_href_regex(doc, link_regex)
	ids = []
	doc.xpath('//a[@href]').each do |link|
		if link['href'] =~ /#{link_regex}/
			ids << link['href'].split("=").last
		end
	end
	ids
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
	# companies_ids.each do |p_id|
	# 	proposed_dissertation_page = get_html(COMPANY_URL+p_id)
	# 	dissertation_ids += get_ids_in_link_by_href_regex(proposed_dissertation_page, THESIS_REGEX)
	# end
	dissertation_ids.each do |thesis|
		dissertation_pages << get_html(DISSERTATION_URL+thesis)
	end
	dissertation_pages
end

def dissertations_pages_to_array_of_hashes(dissertations_pages)
	all_dissertations = Array.new
	dissertations_pages.each do |dis|
		dissertation = Hash.new
		dis.css('td.conteudocentral > table tr').each do |tab|
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
