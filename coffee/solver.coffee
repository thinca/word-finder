class WordFinder
  # ex.
  # word = "漢x"
  # word = "y字"
  #
  # symbol = "x"
  # symbol = "y"
  #
  # candidate = {
  #   symbol1: "漢"
  #   symbol2: "字"
  # }
  #
  # candidateGroup = [candidate1, candidate2...]
  #
  # candidateGroups = {
  #   word1: group1
  #   word2: group2
  #   ...
  # ]

  PLACEHOLDERS = /[a-zA-Z0-9_!?-]/

  constructor: (@data) ->
    @candidateGroups = {}
    @symbols = {}

  addWord: (word) ->
    # return if @candidateGroups[word]
    textData = @data[word.length]
    [pattern, symbolInfos] = @makeSearchPattern(word)
    _.keys(symbolInfos).forEach (v) =>
      @symbols[v] = true
    matched = textData.match(new RegExp("^#{pattern}$", 'gm'))
    @candidateGroups[word] =
      symbolInfos: symbolInfos
      candidates:
        (matched || []).map (word) =>
          @extractCandidate(word, symbolInfos)

  makeSearchPattern: (word) ->
    symbolInfos = {}
    count = 0
    [
      word
        .split('')
        .map (ch, i) ->
          if ch.match PLACEHOLDERS
            if symbolInfos[ch]
              "\\#{symbolInfos[ch].backRefCount}"
            else
              symbolInfos[ch] =
                stringIndex: i
                backRefCount: ++count
              "(.)"
          else
            ch
        .join('')
      symbolInfos
    ]

  extractCandidate: (word, symbolInfos) ->
    _.mapObject symbolInfos, (info) ->
      word[info.stringIndex]

  filterGroupsBySymbol: (groups, symbol) ->
    _.pick groups, (group) -> _.has(group.symbolInfos, symbol)

  narrow: (groups, symbol) ->
    keyArrays =
      _.values(groups).map (group) ->
        group.candidates.map (candidate) -> candidate[symbol]
    narrowed = _.intersection(keyArrays...)
    _.mapObject groups, (group) ->
      _.extend(
        group
        candidates:
          group.candidates.filter (candidate) ->
            narrowed.some (char) -> candidate[symbol] == char
      )


  buildResults: (candidatesList, candidate = {}) ->
    pred = (cand) ->
      _.pairs(cand).every ([symbol, char]) ->
        !_.has(candidate, symbol) || candidate[symbol] == char

    candidates = _.first(candidatesList).filter pred
    if candidatesList.length == 1
      candidates.map (c) -> _.extend(_.clone(candidate), c)
    else
      _.flatten(
        candidates
          .map (c) =>
            @buildResults(
              _.rest(candidatesList)
              _.extend(_.clone(candidate), c)
            )
        1
      )


  getResults: ->
    groups =
      _.reduce(
        _.keys(@symbols)
        (candidateGroups, symbol) =>
          filteredGroup = @filterGroupsBySymbol(candidateGroups, symbol)
          narrowed = @narrow(filteredGroup, symbol)
          _.extend(candidateGroups, narrowed)
        @candidateGroups
      )
    _.uniq @buildResults(_.values(groups).map (o) -> o.candidates)



$ ->
  data = null

  charNums = ['2', '3', '4', '5']
  $.when(
    (charNums.map (n) -> $.ajax("data/#{n}words.txt"))...
  ).done (args...) ->
    data = _.object charNums, args.map(_.first)


  $('#search').on 'click', ->
    $result_area = $('#result-area')
    if data == null
      $result_area.text('データダウンロード中')
      return

    finder = new WordFinder(data)
    words =
      $('#input-area')
        .val()
        .split(/\s+/)
        .filter(_.identity)

    if words.length == 0
      $result_area.text('単語を入力してください')
      return

    words.forEach (word) ->
      finder.addWord word

    limit = 5

    results = finder.getResults()
    if results.length == 0
      resultHTML = "<div>見付かりませんでした</div>"
    else
      slopped = results.length - limit
      results = results[0...limit]
      resultStrings =
        results
          .map (result) ->
            _.pairs(result)
              .map ([symbol, value]) ->
                "#{symbol}=#{value}"
              .join(" ")

      resultHTML = resultStrings
        .map (text) -> "<div>#{text}</div>"
        .join("\n")
      if 0 < slopped
        resultHTML += "<div>他 #{slopped} 件</div>"
    $result_area.html(resultHTML)
