awssum = require 'awssum'
path   = require "path"
#amazon = awssum.load 'amazon/amazon'
amazon = require 'awssum-amazon'
ustr = require 'underscore.string'

# Returns configuration for the given environment.
#
# `env`: `production`, `development`, `staging`, `testing` etc.
exports.forEnvironment = (env) ->
    config =
        env: env

    envSuffix = if env != 'production' then "-#{env}" else ""

    config.server =
        operationMode : 'rw'

    #MongoDB
    config.mongodb =
        host: process.env.CASTLE_MONGODB_HOST || 'localhost'
        port: process.env.CASTLE_MONGODB_PORT || 27017
        db: "castle#{envSuffix}"

    #Redis
    config.redis =
        dbs: {}

    config.se =
        host: process.env.CASTLE_SEARCH_ENGINE_HOST || null
        port: process.env.CASTLE_SEARCH_ENGINE_PORT || '9200'

    if env == 'production'
        config.redis.dbs =
            datastore: 0
            cache: 1
            pubsub: 2
            leaderboard : 3
            host: process.env.CASTLE_REDIS_HOST || 'localhost'
            port: process.env.CASTLE_REDIS_PORT || 6379
    else
        config.redis.dbs =
            datastore: 10
            cache: 11
            pubsub: 12
            leaderboard : 3
            host: process.env.CASTLE_REDIS_HOST || 'localhost'
            port: process.env.CASTLE_REDIS_PORT || 6379

    #Gearman
    config.gearman =
        host: 'localhost'
        port: 4730

    #APN

    config.quests =
        ppl2Threshold : 1000

    if env == 'production'
        config.leaderboard =
            validExpiration : 60 * 60 * 24 * 2
        config.apn =
            gateway : 'gateway.push.apple.com'
            cert : path.resolve(__dirname,'../../../../system/apns/apns_production_cert.pem')
            key : path.resolve(__dirname,'../../../../system/apns/apns_production_key.pem')

        config.iap =
            applePassword : 'e474684518254d00bcbf151b11784128'
            googlePublicKeyPath : path.resolve(__dirname,'../../../../system/iap/') + '/'
            shared_secret : 'e474684518254d00bcbf151b11784128'

        config.gcm =
            apiKey : 'AIzaSyBy6WUDXT3Vjl87uDdYg6WbWEy6Y8PD6Zo'

    else if env == 'staging'

        config.quests.ppl2Threshold = 10

        config.leaderboard =
            validExpiration : 60 * 60

        config.apn =
            gateway : 'gateway.sandbox.push.apple.com'
            cert : path.resolve(__dirname,'../../../../system/apns/apns_production_cert.pem')
            key : path.resolve(__dirname,'../../../../system/apns/apns_production_key.pem')

        config.iap =
            applePassword : 'e474684518254d00bcbf151b11784128'
            googlePublicKeyPath : path.resolve(__dirname,'../../../../system/iap/') + '/'
            shared_secret : 'e474684518254d00bcbf151b11784128'

        config.gcm =
            apiKey : 'AIzaSyBy6WUDXT3Vjl87uDdYg6WbWEy6Y8PD6Zo'

    config.notification =
            statsResetInterval      : 1000 * 60 * 60 * 24 # daily reset !!!
            maxSentEvents           : 100000
            maxSentEventsPerUser    : 20
            aggregationMethod       : "count" # count, collect
            events :
                "level.played" :
                    maxSentEventsPerUser    : 2
                    flushInterval           : 1000*60*60*12 # daily flush !!!
                    langs:
                        en:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} played your game: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} played your games: #{subject_name}"
                        pl:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} zagrał w twoją grę: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} zagrał w twoje gry: #{subject_name}"
                        nl:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} heeft je spel gespeeld: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} vindt je spel leuk: #{subject_name}"
                        it:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} ha giocato il tuo gioco: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} gradisce il tuo gioco: #{subject_name}"
                        fr:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} a joué à ton jeu : #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} aime ton jeu : #{subject_name}"
                        es:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} ha jugado a tu juego: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "A #{post_user_name} le gusta tu juego: #{subject_name}"
                        de:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} hat dein Spiel gespielt: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} mag dein Spiel: #{subject_name}"
                        pt:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} jogou seu jogo: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} curtiu seu jogo: #{subject_name}"
                    singular_event_tag      : 'P1'
                    plural_event_tag        : 'P2'
                    target_action           : 'nop'
                "level.liked" :
                    maxSentEventsPerUser    : 2
                    flushInterval           : 1000*60*60*12 # daily flush !!!
                    langs:
                        en:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} likes your game: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} likes your games: #{subject_name} "
                        pl:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} lubi twoją grę: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} lubi twoje gry: #{subject_name}"
                        nl:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} vindt je spel leuk: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} vindt je spelletjes leuk: #{subject_name}"
                        it:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} gradisce il tuo gioco: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} gradisce i tuoi giochi: #{subject_name}"
                        fr:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} aime ton jeu: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} aime tes jeux : #{subject_name}"
                        es:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "A #{post_user_name} le gusta tu juego: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "A #{post_user_name} le gustan tus juegos: #{subject_name}"
                        de:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} mag dein Spiel: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} mag deine Spiele: #{subject_name}"
                        pt:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} curtiu seu jogo: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} curtiu seus jogos: #{subject_name}"
                    singular_event_tag      : 'L1'
                    plural_event_tag        : 'L2'
                    target_action           : 'nop'
                "level.commented" :
                    aggregationMethod       : "collect" # count, collect
                    maxSentEventsPerUser    : 4
                    flushInterval           : 1000*60
                    langs:
                        en:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} commented on your game: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} commented on your games: #{subject_name}"
                        pl:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} skomentował twoją grę: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} skomentował twoje gry: #{subject_name}"
                        nl:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} heeft gereageerd op je spel: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} heeft gereageerd op je spelletjes: #{subject_name}"
                        it:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} ha fatto un commento sul tuo gioco: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} ha fatto un commento sui tuoi giochi: #{subject_name}"
                        fr:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} a commenté ton jeu : #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} a commenté tes jeux : #{subject_name}"
                        es:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} ha comentado sobre tu juego: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} ha comentado sobre tus juegos: #{subject_name}"
                        de:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} hat dein Spiel kommentiert:#{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} hat deine Spiele kommentiert:#{subject_name}"
                        pt:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} comentou em seu jogo: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} comentou em seus jogos: #{subject_name}"
                    singular_event_tag      : 'C1'
                    plural_event_tag        : 'C2'
                    target_action           : 'nop'
                "level.published" :
                    aggregationMethod       : "collect" # count, collect
                    maxSentEventsPerUser    : 5
                    flushInterval           : 1000*60
                    langs:
                        en:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} published a new game: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} published a new games: #{subject_name}"
                        pl:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} opublikował nową grę: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name}opublikował nowe gry: #{subject_name}"
                        nl:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} heeft een nieuw spel gepubliceerd: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} heeft nieuwe spelletjes gepubliceerd: #{subject_name}"
                        it:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} ha pubblicato un nuovo gioco: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} ha pubblicato dei nuovi giochi: #{subject_name}"
                        fr:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} a publié un nouveau jeu : #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} a publié de nouveaux jeux : #{subject_name}"
                        es:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} ha publicado un juego nuevo: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} ha publicado juegos nuevos: #{subject_name}"
                        de:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} hat ein neues Spiel publiziert: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} hat neue Spiele publiziert: #{subject_name}"
                        pt:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} publicou um jogo novo: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} publicou jogos novos: #{subject_name}"
                    singular_event_tag      : 'F1'
                    plural_event_tag        : 'F2'
                    target_action           : 'nop'
                "level.editor_choice.seleceted.author" :
                    aggregationMethod       : "collect" # count, collect
                    maxSentEventsPerUser    : -1
                    flushInterval           : 1000*60
                    langs:
                        en:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "Congrats! Your level #{subject_name} has been selected to Editor's Pick"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "Congrats! Your levels #{subject_name} has been selected to Editor's Pick"
                        pl:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "Gratulacje! Twoja gra #{subject_name} została wyróżniona!"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "Gratulacje! Twoje gry #{subject_name} zostały wyróżnione!"
                        nl:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "Gefeliciteerd! Je spel #{subject_name} staat in de kijker!"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "Gefeliciteerd! Je spelletjes #{subject_name} staan in de kijker!"
                        it:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "Congratulazioni! Il tuo gioco #{subject_name} è stato messo in evidenza!"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "Congratulazioni! I tuoi giochi #{subject_name} sono stati messi in evidenza!"
                        fr:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "Félicitations ! Ton jeu #{subject_name} a été mis en vedette !"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "Félicitations ! Tes jeux #{subject_name} ont été mis en vedette !"
                        es:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "¡Enhorabuena! ¡Tu juego #{subject_name} ha sido promocionado!"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "¡Enhorabuena! ¡Tus juegos #{subject_name} han sido promocionados!"
                        de:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "Glückwunsch! Dein Spiel #{subject_name} wurde gefördert!"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "Glückwunsch! Deine Spiele #{subject_name} wurden gefördert!"
                        pt:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "Parabéns! Seu jogo #{subject_name} foi Destacado!"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "Parabéns! Seus jogos #{subject_name} foram Destacados!"
                    singular_event_tag      : 'E1'
                    plural_event_tag        : 'E2'
                    target_action           : 'nop'
                    aggregationMethod       : "collect" # count, collect
                    maxSentEventsPerUser    : 4
                    flushInterval           : 1000*60
                    langs:
                        en:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "New level #{subject_name} has been selected to Editor's Pick"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "New levels #{subject_name} has been selected to Editor's Pick"
                        pl:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "Nowa gra #{subject_name} została wyróżniona"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "Nowe gry #{subject_name} zostały wyróżnione"
                        nl:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "Nieuw spel #{subject_name} in de kijker"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "Nieuwe spelletjes #{subject_name} in de kijker"
                        it:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "Il nuovo gioco #{subject_name} è stato messo in evidenza"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "I nuovi giochi #{subject_name} sono stati messi in evidenza!"
                        fr:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "Le nouveau jeu #{subject_name} a été mis en vedette"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "Les nouveaux jeux #{subject_name} ont été mis en vedette"
                        es:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "Un nuevo juego #{subject_name} ha sido promocionado"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "Hay nuevos juegos #{subject_name} que han sido promocionados"
                        de:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "Ein neues Spiel #{subject_name} wurde gefördert!"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "Neue Spiele #{subject_name} wurden gefördert!"
                        pt:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "Um novo jogo #{subject_name} foi destacado"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "Foram destacados novos jogos #{subject_name}"
                    singular_event_tag      : 'E3'
                    plural_event_tag        : 'E4'
                    target_action           : 'nop'
                "post.commented" :
                    aggregationMethod       : "collect" # count, collect
                    maxSentEventsPerUser    : 4
                    flushInterval           : 1000*60
                    langs:
                        en:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} also commented on a game: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} also commented on a games: #{subject_name}"
                        pl:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} także skomentował grę: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} także skomentował grę: #{subject_name}"
                        nl:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} heeft ook gereageerd op een spel: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} heeft ook gereageerd op spelletjes: #{subject_name}"
                        it:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "Anche #{post_user_name} ha fatto un commento su un gioco: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "Anche #{post_user_name} ha fatto un commento su un gioco: #{subject_name}"
                        fr:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} a également commenté un jeu : #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} a également commenté des jeux : #{subject_name}"
                        es:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} también ha comentado sobre un juego: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} también ha comentado sobre unos juegos: #{subject_name}"
                        de:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} hat auch unter #{subject_name} kommentiert"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} hat auch unter #{subject_name} kommentiert"
                        pt:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} também comentou em um jogo: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} também comentou em jogos: #{subject_name}"
                    singular_event_tag      : 'C3'
                    plural_event_tag        : 'C4'
                    target_action           : 'nop'
                "user.followed" :
                    aggregationMethod       : "collect" # count, collect
                    maxSentEventsPerUser    : 4
                    flushInterval           : 1000*60
                    langs:
                        en:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{subject_name} is now following you!"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{subject_name} are now following you!"
                        pl:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{subject_name} obserwuje cię!"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{subject_name} obserwuje cię!"
                        nl:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{subject_name} is je nu aan het volgen!"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{subject_name} zijn je nu aan het volgen!"
                        it:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{subject_name} adesso ti segue!"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{subject_name} adesso ti seguono!"
                        fr:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{subject_name} te suit !"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{subject_name} te suivent !"
                        es:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{subject_name} ahora se ha hecho seguidor tuyo."
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{subject_name} ahora son seguidores tuyos."
                        de:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{subject_name} folgt dir jetzt!"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{subject_name} folgen dir jetzt!"
                        pt:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{subject_name} está agora seguindo você!"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{subject_name} estão agora seguindo você!"
                    singular_event_tag       : 'F3'
                    plural_event_tag         : 'F4'
                    target_action            : 'nop'
                "sys.msg" :
                    aggregationMethod       : "collect"
                    maxSentEventsPerUser    : 1000
                    flushInterval           : 1000*1
                    langs:
                        en:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name}:#{msg}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name}:#{msg}"
                    singular_event_tag       : 'S1'
                    plural_event_tag         : 'S2'
                    target_action            : 'nop'

                "level.highscore.friend.beating" :
                    maxSentEventsPerUser    : 2
                    flushInterval           : 1000 # sec flush !!!
                    langs:
                        en:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} beat your highscore in game: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} beat your highscore in game #{subject_name}"
                        pl:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} pobił twój wynik w grze #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} pobił twój wynik w grze #{subject_name}"
                        nl:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} verbeterde je topscore in #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} verbeterde je topscore in #{subject_name}"
                        it:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} ha battuto il tuo record in #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} ha battuto il tuo record in #{subject_name}"
                        fr:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} a battu ton record dans #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} a battu ton record dans #{subject_name}"
                        es:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} supera tu récord en #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} supera tu récord en #{subject_name}"
                        de:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} hat deinen Highscore geschlagen in #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} hat deinen Highscore geschlagen in #{subject_name}"
                        pt:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} superou sua pontuação máxima em #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} superou sua pontuação máxima em #{subject_name}"
                        ru:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} побил(а) твой рекорд в игре #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} побил(а) твой рекорд в игре #{subject_name}"
                        ko:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} 님이 다음에서 내 최고 점수 갱신: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} 님이 다음에서 내 최고 점수 갱신: #{subject_name}"

                    singular_event_tag      : 'P1'
                    plural_event_tag        : 'P2'
                    target_action           : 'nop'

                "level.highscore.top.beating" :
                    maxSentEventsPerUser    : 2
                    flushInterval           : 1000 # sec flush !!!
                    langs:
                        en:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "#{post_user_name} beat your top highscore in game: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "#{post_user_name} beat your top highscore in game #{subject_name}"
                        pl:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} pobił twój wynik w grze #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} pobił twój wynik w grze #{subject_name}"
                        nl:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} verbeterde je topscore in #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} verbeterde je topscore in #{subject_name}"
                        it:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} ha battuto il tuo record in #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} ha battuto il tuo record in #{subject_name}"
                        fr:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} a battu ton record dans #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} a battu ton record dans #{subject_name}"
                        es:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} supera tu récord en #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} supera tu récord en #{subject_name}"
                        de:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} hat deinen Highscore geschlagen in #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} hat deinen Highscore geschlagen in #{subject_name}"
                        pt:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} superou sua pontuação máxima em #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} superou sua pontuação máxima em #{subject_name}"
                        ru:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} побил(а) твой рекорд в игре #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} побил(а) твой рекорд в игре #{subject_name}"
                        ko:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} 님이 다음에서 내 최고 점수 갱신: #{subject_name}"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{post_user_name} 님이 다음에서 내 최고 점수 갱신: #{subject_name}"
                    singular_event_tag      : 'P1'
                    plural_event_tag        : 'P2'
                    target_action           : 'nop'

                "level.played.top100" :
                    maxSentEventsPerUser    : 2
                    flushInterval           : 1000 # sec flush !!!
                    langs:
                        en:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "Level #{subject_name} has been played over 100 times. Check it out!"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "Level #{subject_name} has been played over 100 times. Check it out!"
                        pl:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} została zgrana już 100 razy!. Sprawdź ją!"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} została zgrana już 100 razy!. Sprawdź ją!"
                        nl:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} zijn al meer dan 100 keer gespeeld. Probeer het nu!"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} zijn al meer dan 100 keer gespeeld. Probeer het nu!"
                        it:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} è stato giocato più di 100 volte. Dacci un’occhiata!"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} è stato giocato più di 100 volte. Dacci un’occhiata!"
                        fr:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} a été joué plus de 100 fois. Va donc y jeter un œil !"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} a été joué plus de 100 fois. Va donc y jeter un œil !"
                        es:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} ha sido jugado más de 100 veces. ¡Mira!"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} ha sido jugado más de 100 veces. ¡Mira!"
                        de:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} wurde bereits 100 mal gespielt. Versuch es mal!"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} wurde bereits 100 mal gespielt. Versuch es mal!"
                        pt:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} foi jogado mais de 100 vezes. Dê uma olhada!"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} foi jogado mais de 100 vezes. Dê uma olhada!"
                        ru:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} пройден(а) уже больше 100 раз. Попробуй и ты!"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} пройден(а) уже больше 100 раз. Попробуй и ты!"
                        ko:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} 님이 100번 이상 플레이했습니다. 확인해 보세요!"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} 님이 100번 이상 플레이했습니다. 확인해 보세요!"

                    singular_event_tag      : 'P1'
                    plural_event_tag        : 'P2'
                    target_action           : 'nop'

                "level.likes.top100" :
                    maxSentEventsPerUser    : 2
                    flushInterval           : 1000 # sec flush !!!
                    langs:
                        en:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "Level #{subject_name} has got 100 likes already. Try it out!"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "Level #{subject_name} has got 100 likes already. Try it out!"
                        pl:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} ma już 100 polubień. Sprawdź ją!"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} ma już 100 polubień. Sprawdź ją!"
                        nl:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} heeft al 100 likes. Probeer het nu!"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} heeft al 100 likes. Probeer het nu!"
                        it:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} ha già ricevuto 100 preferenze. Provalo!"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} ha già ricevuto 100 preferenze. Provalo!"
                        fr:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} a déjà 100 mentions J aime. Essaie-le !"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} a déjà 100 mentions J aime. Essaie-le !"
                        es:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} ya tiene 100 Me gusta. ¡Inténtalo!"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} ya tiene 100 Me gusta. ¡Inténtalo!"
                        de:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} hat bereits 100 Likes. Sieh es dir an!"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} hat bereits 100 Likes. Sieh es dir an!"
                        pt:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} já recebeu 100 curtidas. Experimenta!"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} já recebeu 100 curtidas. Experimenta!"
                        ru:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} нравится уже более чем 100 пользователям. Попробуй и ты!"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} нравится уже более чем 100 пользователям. Попробуй и ты!"
                        ko:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} 님이 이미 100개의 좋아요를 받았습니다. 도전해 보세요!"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} 님이 이미 100개의 좋아요를 받았습니다. 도전해 보세요!"
                    singular_event_tag      : 'P1'
                    plural_event_tag        : 'P2'
                    target_action           : 'nop'

                "user.rank.up" :
                    maxSentEventsPerUser    : 2
                    flushInterval           : 1000 # sec flush !!!
                    langs:
                        en:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "User #{subject_name} reached level #{msg}"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "User #{subject_name} reached level #{msg}"
                        pl:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} zdobywa poziom #{msg}"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} zdobywa poziom #{msg}"
                        nl:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} bereikte niveau #{msg}"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} bereikte niveau #{msg}"
                        it:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} ha raggiungo il livello #{msg}"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} ha raggiungo il livello #{msg}"
                        fr:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} a atteint le niveau #{msg}"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} a atteint le niveau #{msg}"
                        es:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} ha alcanzado el nivel #{msg}"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} ha alcanzado el nivel #{msg}"
                        de:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} erreichte Level #{msg}"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} erreichte Level #{msg}"
                        pt:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} alcançou nível #{msg}"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} alcançou nível #{msg}"
                        ru:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} получил(а) уровень #{msg}"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} получил(а) уровень #{msg}"
                        ko:
                            formatSingularMessage   : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} 도달 레벨 #{msg}"
                            formatPluralMessage     : (subject_name, post_user_name, msg) ->
                                return "#{subject_name} 도달 레벨 #{msg}"

                    singular_event_tag      : 'P1'
                    plural_event_tag        : 'P2'
                    target_action           : 'nop'

                "level.contest.selected" :
                    maxSentEventsPerUser    : 2
                    flushInterval           : 1000 # sec flush !!!
                    langs:
                        en:
                            formatSingularMessage   : (subject_name, post_user_name) ->
                                return "Congrats! Your level #{subject_name} has been selected to Contest"
                            formatPluralMessage     : (subject_name, post_user_name) ->
                                return "Congrats! Your level #{subject_name}  has been selected to Contest"
                    singular_event_tag      : 'P1'
                    plural_event_tag        : 'P2'
                    target_action           : 'nop'





    if env == 'production'
        #AWS
        config.aws =
            key: 'AKIAJRL3YEG26A66VDOQ'
            secret: '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'
            region: amazon.US_WEST_1
            assetsOriginHostnameCloudFront:'cdn.castle.com'
            assetsOriginHostname:"castle-us-west-1-levels#{envSuffix}.s3.amazonaws.com"
            userProfileOriginHostname:"castle-us-west-1-userprofiles#{envSuffix}.s3.amazonaws.com"


        #S3
        config.buckets =
            users: "castle-us-west-1-users#{envSuffix}"
            levels: "castle-us-west-1-levels#{envSuffix}"
            user_profiles: "castle-us-west-1-userprofiles#{envSuffix}"


    #else if env == 'staging'
    else
        #AWS
        config.aws =
            key: 'AKIAJRL3YEG26A66VDOQ'
            secret: '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'
            region: amazon.EU_WEST_1
            assetsOriginHostnameCloudFront:"castle-eu1-levels#{envSuffix}.s3.amazonaws.com"
            assetsOriginHostname:"castle-eu1-levels#{envSuffix}.s3.amazonaws.com"
            userProfileOriginHostname:"incuvo-castle-eu1-userprofiles#{envSuffix}.s3.amazonaws.com"

        #S3
        config.buckets =
            users: "castle-eu1-users#{envSuffix}"
            levels: "castle-eu1-levels#{envSuffix}"
            user_profiles: "incuvo-castle-eu1-userprofiles#{envSuffix}"


#        config.notification.events["level.played"].flushInterval            = 1000*5
#        config.notification.events["level.played"].maxSentEventsPerUser     = 100
#
#        config.notification.events["level.liked"].flushInterval             = 1000*5
#        config.notification.events["level.liked"].maxSentEventsPerUser      = 100
#
#        config.notification.events["level.commented"].flushInterval         = 1000*5
#        config.notification.events["level.commented"].maxSentEventsPerUser  = 100
#
#        config.notification.events["level.published"].flushInterval         = 1000*60
#        config.notification.events["level.published"].maxSentEventsPerUser  = 100
#
#        config.notification.events["level.editor_choice.seleceted.author"].flushInterval        = 1000*15
#        config.notification.events["level.editor_choice.seleceted.author"].maxSentEventsPerUser = -1
#
#        config.notification.events["level.editor_choice.seleceted"].flushInterval               = 1000*60
#        config.notification.events["level.editor_choice.seleceted"].maxSentEventsPerUser        = 100

#        config.notification.events["post.commented"].flushInterval                              = 1000*5
#        config.notification.events["post.commented"].maxSentEventsPerUser                       = 100
#
#        config.notification.events["user.followed"].flushInterval                               = 1000*5
#        config.notification.events["user.followed"].maxSentEventsPerUser                        = 100




    #CORS
    config.cors = {domains: '*'}

    if env == 'staging' || env == 'testing'
        config.cors.domains = ['http://castle-controller.castle.com','https://castle-controller.castle.com','https://staging.castle-console.castle.com','http://staging.castle-console.castle.com','https://staging.castle-controller.castle.com','http://staging.castle-controller.castle.com', 'http://testing.castle-controller.castle.com']

    if env == 'production'
        config.cors.domains = ['https://castle-console.castle.com','https://castle-controller.castle.com','http://castle-controller.castle.com']

    #Apps
    config.apps =
        castle:
            name: 'Castle Revenge App'
            client_id: 'oxGCE1Hypile7yys3sUJmlMOGXjcAswc'
            client_secret: 'NQnR2jVQTOTHmmNcK9c6xWmDIc5dqq00'


    if env == 'production'
        config.lockit =
            levels:
                "558aa256568580947f000814":{"en":"Runner 01","de":"Sprinter 1","pl":"Biegacz 1","nl":"Loper 01","fr":"Coureur 01","it":"Corridore 01","pt":"Corredor 01","es":"Corredor 01","ko":"러너 01","ru":"Забег 01"},
                "558aa2faa8e624967f0009b0":{"en":"Runner 02","de":"Sprinter 2","pl":"Biegacz 2","nl":"Loper 02","fr":"Coureur 02","it":"Corridore 02","pt":"Corredor 02","es":"Corredor 02","ko":"러너 02","ru":"Забег 02"},
                "558aa34ca8e624967f0009b1":{"en":"Runner 03","de":"Sprinter 3","pl":"Biegacz 3","nl":"Loper 03","fr":"Coureur 03","it":"Corridore 03","pt":"Corredor 03","es":"Corredor 03","ko":"러너 03","ru":"Забег 03"},
                "558aa468a8e624967f0009b4":{"en":"Runner 04","de":"Sprinter 4","pl":"Biegacz 4","nl":"Loper 04","fr":"Coureur 04","it":"Corridore 04","pt":"Corredor 04","es":"Corredor 04","ko":"러너 04","ru":"Забег 04"},
                "558aa511568580947f000815":{"en":"Runner 05","de":"Sprinter 5","pl":"Biegacz 5","nl":"Loper 05","fr":"Coureur 05","it":"Corridore 05","pt":"Corredor 05","es":"Corredor 05","ko":"러너 05","ru":"Забег 05"},
                "558aa563568580947f000816":{"en":"Runner 06","de":"Sprinter 6","pl":"Biegacz 6","nl":"Loper 06","fr":"Coureur 06","it":"Corridore 06","pt":"Corredor 06","es":"Corredor 06","ko":"러너 06","ru":"Забег 06"},
                "558aa717568580947f000818":{"en":"Runner 07","de":"Sprinter 7","pl":"Biegacz 7","nl":"Loper 07","fr":"Coureur 07","it":"Corridore 07","pt":"Corredor 07","es":"Corredor 07","ko":"러너 07","ru":"Забег 07"},
                "558aa794568580947f000819":{"en":"Runner 08","de":"Sprinter 8","pl":"Biegacz 8","nl":"Loper 08","fr":"Coureur 08","it":"Corridore 08","pt":"Corredor 08","es":"Corredor 08","ko":"러너 08","ru":"Забег 08"},
                "558aa7dba8e624967f0009b7":{"en":"Runner 09","de":"Sprinter 9","pl":"Biegacz 9","nl":"Loper 09","fr":"Coureur 09","it":"Corridore 09","pt":"Corredor 09","es":"Corredor 09","ko":"러너 09","ru":"Забег 09"},
                "558aa81a568580947f00081a":{"en":"Runner 10","de":"Sprinter 10","pl":"Biegacz 10","nl":"Loper 10","fr":"Coureur 10","it":"Corridore 10","pt":"Corredor 10","es":"Corredor 10","ko":"러너 10","ru":"Забег 10"},
                "53834e44334e23b262000020":{"en":"Pixel Invasion 01","de":"Pixel Invasion 01","pl":"Inwazja Pikseli 01","nl":"Pixelinvasie 01","fr":"Invasion de pixels 01","it":"Invasione di pixel 01","pt":"Invasão Pixelada 01","es":"Invasión Píxel 01","ko":"픽셀 침입 01","ru":"Пиксельное вторжение 01"},
                "53834ec6bea813b062000027":{"en":"Pixel Invasion 02","de":"Pixel Invasion 02","pl":"Inwazja Pikseli 02","nl":"Pixelinvasie 02","fr":"Invasion de pixels 02","it":"Invasione di pixel 02","pt":"Invasão Pixelada 02","es":"Invasión Píxel 02","ko":"픽셀 침입 02","ru":"Пиксельное вторжение 02"},
                "53834f30bea813b062000028":{"en":"Pixel Invasion 03","de":"Pixel Invasion 03","pl":"Inwazja Pikseli 03","nl":"Pixelinvasie 03","fr":"Invasion de pixels 03","it":"Invasione di pixel 03","pt":"Invasão Pixelada 03","es":"Invasión Píxel 03","ko":"픽셀 침입 03","ru":"Пиксельное вторжение 03"},
                "53834f7a334e23b262000021":{"en":"Pixel Invasion 04","de":"Pixel Invasion 04","pl":"Inwazja Pikseli 04","nl":"Pixelinvasie 04","fr":"Invasion de pixels 04","it":"Invasione di pixel 04","pt":"Invasão Pixelada 04","es":"Invasión Píxel 04","ko":"픽셀 침입 04","ru":"Пиксельное вторжение 04"},
                "53834fdf334e23b262000022":{"en":"Pixel Invasion 05","de":"Pixel Invasion 05","pl":"Inwazja Pikseli 05","nl":"Pixelinvasie 05","fr":"Invasion de pixels 05","it":"Invasione di pixel 05","pt":"Invasão Pixelada 05","es":"Invasión Píxel 05","ko":"픽셀 침입 05","ru":"Пиксельное вторжение 05"},
                "53835066334e23b262000023":{"en":"Pixel Invasion 06","de":"Pixel Invasion 06","pl":"Inwazja Pikseli 06","nl":"Pixelinvasie 06","fr":"Invasion de pixels 06","it":"Invasione di pixel 06","pt":"Invasão Pixelada 06","es":"Invasión Píxel 06","ko":"픽셀 침입 06","ru":"Пиксельное вторжение 06"},
                "538350a6334e23b262000025":{"en":"Pixel Invasion 07","de":"Pixel Invasion 07","pl":"Inwazja Pikseli 07","nl":"Pixelinvasie 07","fr":"Invasion de pixels 07","it":"Invasione di pixel 07","pt":"Invasão Pixelada 07","es":"Invasión Píxel 07","ko":"픽셀 침입 07","ru":"Пиксельное вторжение 07"},
                "538350f3334e23b262000026":{"en":"Pixel Invasion 08","de":"Pixel Invasion 08","pl":"Inwazja Pikseli 08","nl":"Pixelinvasie 08","fr":"Invasion de pixels 08","it":"Invasione di pixel 08","pt":"Invasão Pixelada 08","es":"Invasión Píxel 08","ko":"픽셀 침입 08","ru":"Пиксельное вторжение 08"},
                "53835155334e23b262000027":{"en":"Pixel Invasion 09","de":"Pixel Invasion 09","pl":"Inwazja Pikseli 09","nl":"Pixelinvasie 09","fr":"Invasion de pixels 09","it":"Invasione di pixel 09","pt":"Invasão Pixelada 09","es":"Invasión Píxel 09","ko":"픽셀 침입 09","ru":"Пиксельное вторжение 09"},
                "538351ae334e23b262000028":{"en":"Pixel Invasion 10","de":"Pixel Invasion 10","pl":"Inwazja Pikseli 10","nl":"Pixelinvasie 10","fr":"Invasion de pixels 10","it":"Invasione di pixel 10","pt":"Invasão Pixelada 10","es":"Invasión Píxel 10","ko":"픽셀 침입 10","ru":"Пиксельное вторжение 10"},
                "53a1558a1a7e125b3800001e":{"en":"Castle Pirates 01","de":"Castle Piraten 01","pl":"Piraci z Createrrii 01","nl":"Piraten in Castle 01","fr":"Pirates de Castle 01","it":"Pirati di Castle 01","pt":"Piratas de Castle 01","es":"Piratas de Castle 01","ko":"Castle 해적 01","ru":"Пираты Castle 01"},
                "53a1564846c7275d38000016":{"en":"Castle Pirates 02","de":"Castle Piraten 02","pl":"Piraci z Createrrii 02","nl":"Piraten in Castle 02","fr":"Pirates de Castle 02","it":"Pirati di Castle 02","pt":"Piratas de Castle 02","es":"Piratas de Castle 02","ko":"Castle 해적 02","ru":"Пираты Castle 02"},
                "53a156721a7e125b3800001f":{"en":"Castle Pirates 03","de":"Castle Piraten 03","pl":"Piraci z Createrrii 03","nl":"Piraten in Castle 03","fr":"Pirates de Castle 03","it":"Pirati di Castle 03","pt":"Piratas de Castle 03","es":"Piratas de Castle 03","ko":"Castle 해적 03","ru":"Пираты Castle 03"},
                "53a156a71a7e125b38000020":{"en":"Castle Pirates 04","de":"Castle Piraten 04","pl":"Piraci z Createrrii 04","nl":"Piraten in Castle 04","fr":"Pirates de Castle 04","it":"Pirati di Castle 04","pt":"Piratas de Castle 04","es":"Piratas de Castle 04","ko":"Castle 해적 04","ru":"Пираты Castle 04"},
                "53a156f946c7275d38000017":{"en":"Castle Pirates 05","de":"Castle Piraten 05","pl":"Piraci z Createrrii 05","nl":"Piraten in Castle 05","fr":"Pirates de Castle 05","it":"Pirati di Castle 05","pt":"Piratas de Castle 05","es":"Piratas de Castle 05","ko":"Castle 해적 05","ru":"Пираты Castle 05"},
                "53a157431a7e125b38000021":{"en":"Castle Pirates 06","de":"Castle Piraten 06","pl":"Piraci z Createrrii 06","nl":"Piraten in Castle 06","fr":"Pirates de Castle 06","it":"Pirati di Castle 06","pt":"Piratas de Castle 06","es":"Piratas de Castle 06","ko":"Castle 해적 06","ru":"Пираты Castle 06"},
                "53a1576e46c7275d38000018":{"en":"Castle Pirates 07","de":"Castle Piraten 07","pl":"Piraci z Createrrii 07","nl":"Piraten in Castle 07","fr":"Pirates de Castle 07","it":"Pirati di Castle 07","pt":"Piratas de Castle 07","es":"Piratas de Castle 07","ko":"Castle 해적 07","ru":"Пираты Castle 07"},
                "53a1578f1a7e125b38000022":{"en":"Castle Pirates 08","de":"Castle Piraten 08","pl":"Piraci z Createrrii 08","nl":"Piraten in Castle 08","fr":"Pirates de Castle 08","it":"Pirati di Castle 08","pt":"Piratas de Castle 08","es":"Piratas de Castle 08","ko":"Castle 해적 08","ru":"Пираты Castle 08"},
                "53a157cf1a7e125b38000023":{"en":"Castle Pirates 09","de":"Castle Piraten 09","pl":"Piraci z Createrrii 09","nl":"Piraten in Castle 09","fr":"Pirates de Castle 09","it":"Pirati di Castle 09","pt":"Piratas de Castle 09","es":"Piratas de Castle 09","ko":"Castle 해적 09","ru":"Пираты Castle 09"},
                "53a157fd1a7e125b38000024":{"en":"Castle Pirates 10","de":"Castle Piraten 10","pl":"Piraci z Createrrii 10","nl":"Piraten in Castle 10","fr":"Pirates de Castle 10","it":"Pirati di Castle 10","pt":"Piratas de Castle 10","es":"Piratas de Castle 10","ko":"Castle 해적 10","ru":"Пираты Castle 10"},
                "532c11cbfb99f2d15f00331d":{"en":"Dead Boy 01","de":"Dead Boy 1","pl":"Omen 01","nl":"Dode jongen 1","fr":"Garçon mort 01","it":"Dead Boy 1","pt":"Menino Zumbi 1","es":"Chico muerto 1","ko":"죽은 소년 1","ru":"Мертвячок 1"},
                "532c11cbfb99f2d15f00331e":{"en":"Dead Boy 02","de":"Dead Boy 2","pl":"Omen 02","nl":"Dode jongen 2","fr":"Garçon mort 02","it":"Dead Boy 2","pt":"Menino Zumbi 2","es":"Chico muerto 2","ko":"죽은 소년 2","ru":"Мертвячок 2"},
                "532c11ccfb99f2d15f00331f":{"en":"Dead Boy 03","de":"Dead Boy 3","pl":"Omen 03","nl":"Dode jongen 3","fr":"Garçon mort 03","it":"Dead Boy 3","pt":"Menino Zumbi 3","es":"Chico muerto 3","ko":"죽은 소년 3","ru":"Мертвячок 3"},
                "532d58c27c9a46f7640017c5":{"en":"Dead Boy 04","de":"Dead Boy 4","pl":"Omen 04","nl":"Dode jongen 4","fr":"Garçon mort 04","it":"Dead Boy 4","pt":"Menino Zumbi 4","es":"Chico muerto 4","ko":"죽은 소년 4","ru":"Мертвячок 4"},
                "532eba56b0c633f964004881":{"en":"Dead Boy 05","de":"Dead Boy 5","pl":"Omen 05","nl":"Dode jongen 5","fr":"Garçon mort 05","it":"Dead Boy 5","pt":"Menino Zumbi 5","es":"Chico muerto 5","ko":"죽은 소년 5","ru":"Мертвячок 5"},
                "532fff227c9a46f764004fb6":{"en":"Dead Boy 06","de":"Dead Boy 6","pl":"Omen 06","nl":"Dode jongen 6","fr":"Garçon mort 06","it":"Dead Boy 6","pt":"Menino Zumbi 6","es":"Chico muerto 6","ko":"죽은 소년 6","ru":"Мертвячок 6"},
                "5331a39c2a4036fa640076e6":{"en":"Dead Boy 07","de":"Dead Boy 7","pl":"Omen 07","nl":"Dode jongen 7","fr":"Garçon mort 07","it":"Dead Boy 7","pt":"Menino Zumbi 7","es":"Chico muerto 7","ko":"죽은 소년 7","ru":"Мертвячок 7"},
                "5332d1052a4036fa640089bc":{"en":"Dead Boy 08","de":"Dead Boy 8","pl":"Omen 08","nl":"Dode jongen 8","fr":"Garçon mort 08","it":"Dead Boy 8","pt":"Menino Zumbi 8","es":"Chico muerto 8","ko":"죽은 소년 8","ru":"Мертвячок 8"},
                "5334029fb0c633f96400a9b8":{"en":"Dead Boy 09","de":"Dead Boy 9","pl":"Omen 09","nl":"Dode jongen 9","fr":"Garçon mort 09","it":"Dead Boy 9","pt":"Menino Zumbi 9","es":"Chico muerto 9","ko":"죽은 소년 9","ru":"Мертвячок 9"},
                "53355bc89f8553fc51000142":{"en":"Dead Boy 10","de":"Dead Boy 10","pl":"Omen 10","nl":"Dode jongen 10","fr":"Garçon mort 10","it":"Dead Boy 10","pt":"Menino Zumbi 10","es":"Chico muerto 10","ko":"죽은 소년 10","ru":"Мертвячок 10"}

    else if env == 'staging'
        config.lockit =
            levels:
                "558aba18d1005d01490000d8":{"en":"Runner 01","de":"Sprinter 1","pl":"Biegacz 1","nl":"Loper 01","fr":"Coureur 01","it":"Corridore 01","pt":"Corredor 01","es":"Corredor 01","ko":"러너 01","ru":"Забег 01"},
                "558aba288081130349000133":{"en":"Runner 02","de":"Sprinter 2","pl":"Biegacz 2","nl":"Loper 02","fr":"Coureur 02","it":"Corridore 02","pt":"Corredor 02","es":"Corredor 02","ko":"러너 02","ru":"Забег 02"},
                "558aba358081130349000134":{"en":"Runner 03","de":"Sprinter 3","pl":"Biegacz 3","nl":"Loper 03","fr":"Coureur 03","it":"Corridore 03","pt":"Corredor 03","es":"Corredor 03","ko":"러너 03","ru":"Забег 03"},
                "558aba3fd1005d01490000d9":{"en":"Runner 04","de":"Sprinter 4","pl":"Biegacz 4","nl":"Loper 04","fr":"Coureur 04","it":"Corridore 04","pt":"Corredor 04","es":"Corredor 04","ko":"러너 04","ru":"Забег 04"},
                "558aba87d1005d01490000da":{"en":"Runner 05","de":"Sprinter 5","pl":"Biegacz 5","nl":"Loper 05","fr":"Coureur 05","it":"Corridore 05","pt":"Corredor 05","es":"Corredor 05","ko":"러너 05","ru":"Забег 05"},
                "558aba948081130349000135":{"en":"Runner 06","de":"Sprinter 6","pl":"Biegacz 6","nl":"Loper 06","fr":"Coureur 06","it":"Corridore 06","pt":"Corredor 06","es":"Corredor 06","ko":"러너 06","ru":"Забег 06"},
                "558aba9d8081130349000136":{"en":"Runner 07","de":"Sprinter 7","pl":"Biegacz 7","nl":"Loper 07","fr":"Coureur 07","it":"Corridore 07","pt":"Corredor 07","es":"Corredor 07","ko":"러너 07","ru":"Забег 07"},
                "558abaa7d1005d01490000db":{"en":"Runner 08","de":"Sprinter 8","pl":"Biegacz 8","nl":"Loper 08","fr":"Coureur 08","it":"Corridore 08","pt":"Corredor 08","es":"Corredor 08","ko":"러너 08","ru":"Забег 08"},
                "558abab68081130349000137":{"en":"Runner 09","de":"Sprinter 9","pl":"Biegacz 9","nl":"Loper 09","fr":"Coureur 09","it":"Corridore 09","pt":"Corredor 09","es":"Corredor 09","ko":"러너 09","ru":"Забег 09"},
                "558abac28081130349000138":{"en":"Runner 10","de":"Sprinter 10","pl":"Biegacz 10","nl":"Loper 10","fr":"Coureur 10","it":"Corridore 10","pt":"Corredor 10","es":"Corredor 10","ko":"러너 10","ru":"Забег 10"},
                "537b2f8f5c146e3425000002":{"en":"Pixel Invasion 01","de":"Pixel Invasion 01","pl":"Inwazja Pikseli 01","nl":"Pixelinvasie 01","fr":"Invasion de pixels 01","it":"Invasione di pixel 01","pt":"Invasão Pixelada 01","es":"Invasión Píxel 01","ko":"픽셀 침입 01","ru":"Пиксельное вторжение 01"},
                "537b2fba5c146e3425000004":{"en":"Pixel Invasion 02","de":"Pixel Invasion 02","pl":"Inwazja Pikseli 02","nl":"Pixelinvasie 02","fr":"Invasion de pixels 02","it":"Invasione di pixel 02","pt":"Invasão Pixelada 02","es":"Invasión Píxel 02","ko":"픽셀 침입 02","ru":"Пиксельное вторжение 02"},
                "537b2fc65c146e3425000005":{"en":"Pixel Invasion 03","de":"Pixel Invasion 03","pl":"Inwazja Pikseli 03","nl":"Pixelinvasie 03","fr":"Invasion de pixels 03","it":"Invasione di pixel 03","pt":"Invasão Pixelada 03","es":"Invasión Píxel 03","ko":"픽셀 침입 03","ru":"Пиксельное вторжение 03"},
                "53834a0ef20f135a4c000028":{"en":"Pixel Invasion 04","de":"Pixel Invasion 04","pl":"Inwazja Pikseli 04","nl":"Pixelinvasie 04","fr":"Invasion de pixels 04","it":"Invasione di pixel 04","pt":"Invasão Pixelada 04","es":"Invasión Píxel 04","ko":"픽셀 침입 04","ru":"Пиксельное вторжение 04"},
                "537b2ffb3879773625000008":{"en":"Pixel Invasion 05","de":"Pixel Invasion 05","pl":"Inwazja Pikseli 05","nl":"Pixelinvasie 05","fr":"Invasion de pixels 05","it":"Invasione di pixel 05","pt":"Invasão Pixelada 05","es":"Invasión Píxel 05","ko":"픽셀 침입 05","ru":"Пиксельное вторжение 05"},
                "537b2f853879773625000003":{"en":"Pixel Invasion 06","de":"Pixel Invasion 06","pl":"Inwazja Pikseli 06","nl":"Pixelinvasie 06","fr":"Invasion de pixels 06","it":"Invasione di pixel 06","pt":"Invasão Pixelada 06","es":"Invasión Píxel 06","ko":"픽셀 침입 06","ru":"Пиксельное вторжение 06"},
                "537b2fa83879773625000004":{"en":"Pixel Invasion 07","de":"Pixel Invasion 07","pl":"Inwazja Pikseli 07","nl":"Pixelinvasie 07","fr":"Invasion de pixels 07","it":"Invasione di pixel 07","pt":"Invasão Pixelada 07","es":"Invasión Píxel 07","ko":"픽셀 침입 07","ru":"Пиксельное вторжение 07"},
                "537b2f9c5c146e3425000003":{"en":"Pixel Invasion 08","de":"Pixel Invasion 08","pl":"Inwazja Pikseli 08","nl":"Pixelinvasie 08","fr":"Invasion de pixels 08","it":"Invasione di pixel 08","pt":"Invasão Pixelada 08","es":"Invasión Píxel 08","ko":"픽셀 침입 08","ru":"Пиксельное вторжение 08"},
                "537b30693879773625000009":{"en":"Pixel Invasion 09","de":"Pixel Invasion 09","pl":"Inwazja Pikseli 09","nl":"Pixelinvasie 09","fr":"Invasion de pixels 09","it":"Invasione di pixel 09","pt":"Invasão Pixelada 09","es":"Invasión Píxel 09","ko":"픽셀 침입 09","ru":"Пиксельное вторжение 09"},
                "537b2fb33879773625000005":{"en":"Pixel Invasion 10","de":"Pixel Invasion 10","pl":"Inwazja Pikseli 10","nl":"Pixelinvasie 10","fr":"Invasion de pixels 10","it":"Invasione di pixel 10","pt":"Invasão Pixelada 10","es":"Invasión Píxel 10","ko":"픽셀 침입 10","ru":"Пиксельное вторжение 10"},
                "53a15d034d5e921702000018":{"en":"Castle Pirates 01","de":"Castle Piraten 01","pl":"Piraci z Createrrii 01","nl":"Piraten in Castle 01","fr":"Pirates de Castle 01","it":"Pirati di Castle 01","pt":"Piratas de Castle 01","es":"Piratas de Castle 01","ko":"Castle 해적 01","ru":"Пираты Castle 01"},
                "53a15d1d4d5e921702000019":{"en":"Castle Pirates 02","de":"Castle Piraten 02","pl":"Piraci z Createrrii 02","nl":"Piraten in Castle 02","fr":"Pirates de Castle 02","it":"Pirati di Castle 02","pt":"Piratas de Castle 02","es":"Piratas de Castle 02","ko":"Castle 해적 02","ru":"Пираты Castle 02"},
                "53a15d371d7bcf1902000011":{"en":"Castle Pirates 03","de":"Castle Piraten 03","pl":"Piraci z Createrrii 03","nl":"Piraten in Castle 03","fr":"Pirates de Castle 03","it":"Pirati di Castle 03","pt":"Piratas de Castle 03","es":"Piratas de Castle 03","ko":"Castle 해적 03","ru":"Пираты Castle 03"},
                "53a15d724d5e92170200001a":{"en":"Castle Pirates 04","de":"Castle Piraten 04","pl":"Piraci z Createrrii 04","nl":"Piraten in Castle 04","fr":"Pirates de Castle 04","it":"Pirati di Castle 04","pt":"Piratas de Castle 04","es":"Piratas de Castle 04","ko":"Castle 해적 04","ru":"Пираты Castle 04"},
                "53a15d921d7bcf1902000012":{"en":"Castle Pirates 05","de":"Castle Piraten 05","pl":"Piraci z Createrrii 05","nl":"Piraten in Castle 05","fr":"Pirates de Castle 05","it":"Pirati di Castle 05","pt":"Piratas de Castle 05","es":"Piratas de Castle 05","ko":"Castle 해적 05","ru":"Пираты Castle 05"},
                "53a15db64d5e92170200001b":{"en":"Castle Pirates 06","de":"Castle Piraten 06","pl":"Piraci z Createrrii 06","nl":"Piraten in Castle 06","fr":"Pirates de Castle 06","it":"Pirati di Castle 06","pt":"Piratas de Castle 06","es":"Piratas de Castle 06","ko":"Castle 해적 06","ru":"Пираты Castle 06"},
                "53a15ddb4d5e92170200001c":{"en":"Castle Pirates 07","de":"Castle Piraten 07","pl":"Piraci z Createrrii 07","nl":"Piraten in Castle 07","fr":"Pirates de Castle 07","it":"Pirati di Castle 07","pt":"Piratas de Castle 07","es":"Piratas de Castle 07","ko":"Castle 해적 07","ru":"Пираты Castle 07"},
                "53a15df24d5e92170200001d":{"en":"Castle Pirates 08","de":"Castle Piraten 08","pl":"Piraci z Createrrii 08","nl":"Piraten in Castle 08","fr":"Pirates de Castle 08","it":"Pirati di Castle 08","pt":"Piratas de Castle 08","es":"Piratas de Castle 08","ko":"Castle 해적 08","ru":"Пираты Castle 08"},
                "53a15e1f1d7bcf1902000013":{"en":"Castle Pirates 09","de":"Castle Piraten 09","pl":"Piraci z Createrrii 09","nl":"Piraten in Castle 09","fr":"Pirates de Castle 09","it":"Pirati di Castle 09","pt":"Piratas de Castle 09","es":"Piratas de Castle 09","ko":"Castle 해적 09","ru":"Пираты Castle 09"},
                "53a15e3f4d5e92170200001e":{"en":"Castle Pirates 10","de":"Castle Piraten 10","pl":"Piraci z Createrrii 10","nl":"Piraten in Castle 10","fr":"Pirates de Castle 10","it":"Pirati di Castle 10","pt":"Piratas de Castle 10","es":"Piratas de Castle 10","ko":"Castle 해적 10","ru":"Пираты Castle 10"},
                "53736ab1d0124eb204000015":{"en":"Dead Boy 01","de":"Dead Boy 1","pl":"Omen 01","nl":"Dode jongen 1","fr":"Garçon mort 01","it":"Dead Boy 1","pt":"Menino Zumbi 1","es":"Chico muerto 1","ko":"죽은 소년 1","ru":"Мертвячок 1"},
                "53736b1ebc74c2b404000019":{"en":"Dead Boy 02","de":"Dead Boy 2","pl":"Omen 02","nl":"Dode jongen 2","fr":"Garçon mort 02","it":"Dead Boy 2","pt":"Menino Zumbi 2","es":"Chico muerto 2","ko":"죽은 소년 2","ru":"Мертвячок 2"},
                "53736b27bc74c2b40400001a":{"en":"Dead Boy 03","de":"Dead Boy 3","pl":"Omen 03","nl":"Dode jongen 3","fr":"Garçon mort 03","it":"Dead Boy 3","pt":"Menino Zumbi 3","es":"Chico muerto 3","ko":"죽은 소년 3","ru":"Мертвячок 3"},
                "53736b35d0124eb204000016":{"en":"Dead Boy 04","de":"Dead Boy 4","pl":"Omen 04","nl":"Dode jongen 4","fr":"Garçon mort 04","it":"Dead Boy 4","pt":"Menino Zumbi 4","es":"Chico muerto 4","ko":"죽은 소년 4","ru":"Мертвячок 4"},
                "53736b4fbc74c2b40400001b":{"en":"Dead Boy 05","de":"Dead Boy 5","pl":"Omen 05","nl":"Dode jongen 5","fr":"Garçon mort 05","it":"Dead Boy 5","pt":"Menino Zumbi 5","es":"Chico muerto 5","ko":"죽은 소년 5","ru":"Мертвячок 5"},
                "53736b59bc74c2b40400001c":{"en":"Dead Boy 06","de":"Dead Boy 6","pl":"Omen 06","nl":"Dode jongen 6","fr":"Garçon mort 06","it":"Dead Boy 6","pt":"Menino Zumbi 6","es":"Chico muerto 6","ko":"죽은 소년 6","ru":"Мертвячок 6"},
                "53736b64d0124eb204000018":{"en":"Dead Boy 07","de":"Dead Boy 7","pl":"Omen 07","nl":"Dode jongen 7","fr":"Garçon mort 07","it":"Dead Boy 7","pt":"Menino Zumbi 7","es":"Chico muerto 7","ko":"죽은 소년 7","ru":"Мертвячок 7"},
                "53736b76bc74c2b40400001d":{"en":"Dead Boy 08","de":"Dead Boy 8","pl":"Omen 08","nl":"Dode jongen 8","fr":"Garçon mort 08","it":"Dead Boy 8","pt":"Menino Zumbi 8","es":"Chico muerto 8","ko":"죽은 소년 8","ru":"Мертвячок 8"},
                "53736b90bc74c2b40400001f":{"en":"Dead Boy 09","de":"Dead Boy 9","pl":"Omen 09","nl":"Dode jongen 9","fr":"Garçon mort 09","it":"Dead Boy 9","pt":"Menino Zumbi 9","es":"Chico muerto 9","ko":"죽은 소년 9","ru":"Мертвячок 9"},
                "53736b87bc74c2b40400001e":{"en":"Dead Boy 10","de":"Dead Boy 10","pl":"Omen 10","nl":"Dode jongen 10","fr":"Garçon mort 10","it":"Dead Boy 10","pt":"Menino Zumbi 10","es":"Chico muerto 10","ko":"죽은 소년 10","ru":"Мертвячок 10"}

    return config
