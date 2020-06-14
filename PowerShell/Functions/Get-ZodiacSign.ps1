function Get-ZodiacSign {
    param([datetime]$Birthday)
    switch ($BirthDay.Month) {
        1 { return $Birthday.Day -le 20 ? 'Capricorn': 'Aquarius'}
        2 { return $Birthday.Day -le 19 ? 'Aquarius': 'Aries'}
        3 { return $Birthday.Day -le 20 ? 'Aries': 'Pisces'}
        4 { return $Birthday.Day -le 20 ? 'Pisces': 'Taurus'}
        5 { return $Birthday.Day -le 21 ? 'Taurus': 'Gemini'}
        6 { return $Birthday.Day -le 22 ? 'Gemini': 'Cancer'}
        7 { return $Birthday.Day -le 22 ? 'Cancer': 'Leo'}
        8 { return $Birthday.Day -le 23 ? 'Leo': 'Virgo'}
        9 { return $Birthday.Day -le 23 ? 'Virgo': 'Libra'}
        10 { return $Birthday.Day -le 23 ? 'Libra': 'Scorpio'}
        11 { return $Birthday.Day -le 22 ? 'Scorpio': 'Sagittarius'}
        12 { return $Birthday.Day -le 21 ? 'Sagittarius': 'Capricorn'}
        default {return 'Not Found!'}
    }
}